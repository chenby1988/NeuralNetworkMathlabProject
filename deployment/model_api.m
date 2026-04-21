classdef model_api < handle
    % MODEL_API Wraps trained model as a callable service endpoint
    %   Supports batch prediction and health checks
    
    properties
        Net
        Metadata struct
        IsLoaded logical = false
    end
    
    methods
        function obj = model_api(modelId)
            if nargin >= 1 && ~isempty(modelId)
                obj.load(modelId);
            end
        end
        
        function load(obj, modelId)
            mgr = model_manager();
            [obj.Net, obj.Metadata] = mgr.loadModel(modelId);
            obj.IsLoaded = true;
            Logger.getInstance().info('API: Model %s loaded', modelId);
        end
        
        function predictions = predict(obj, X)
            if ~obj.IsLoaded
                error('API:NotLoaded', 'No model loaded. Call load() first.');
            end
            ExceptionHandler.validateNotEmpty(X, 'Input X');
            
            tStart = tic;
            predictions = obj.Net(X')';
            elapsed = toc(tStart);
            
            Logger.getInstance().debug('API: Prediction for %d samples in %.4f ms', size(X, 1), elapsed*1000);
        end
        
        function result = healthCheck(obj)
            result = struct();
            result.status = 'ok';
            result.model_loaded = obj.IsLoaded;
            if obj.IsLoaded
                result.model_id = obj.Metadata.model_id;
                result.saved_at = obj.Metadata.saved_at;
            end
            result.timestamp = datestr(now);
        end
        
        function batchPredict(obj, inputFile, outputFile)
            % Batch prediction from CSV/MAT file
            [~, ~, ext] = fileparts(inputFile);
            switch lower(ext)
                case '.csv'
                    T = readtable(inputFile);
                    X = T{:, :};
                case '.mat'
                    S = load(inputFile);
                    X = S.X;
                otherwise
                    error('API:UnsupportedFormat', 'Format %s not supported', ext);
            end
            
            Y = obj.predict(X);
            
            Tout = array2table([X, Y], 'VariableNames', [arrayfun(@(i) sprintf('X%d', i), 1:size(X,2), 'UniformOutput', false), {'Prediction'}]);
            writetable(Tout, outputFile);
            Logger.getInstance().info('API: Batch prediction saved to %s', outputFile);
        end
    end
end
