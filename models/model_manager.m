classdef model_manager < handle
    % MODEL_MANAGER Version control and lifecycle management for trained models
    
    properties (Access = private)
        artifactDir char
    end
    
    methods
        function obj = model_manager()
            obj.artifactDir = 'artifacts/models';
            if ~exist(obj.artifactDir, 'dir')
                mkdir(obj.artifactDir);
            end
        end
        
        function modelId = saveModel(obj, net, metadata)
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            uuid = sprintf('%04X', randi(65535));
            modelId = sprintf('model_%s_%s', timestamp, uuid);
            filePath = fullfile(obj.artifactDir, sprintf('%s.mat', modelId));
            
            package = struct();
            package.net = net;
            package.metadata = metadata;
            package.metadata.model_id = modelId;
            package.metadata.saved_at = timestamp;
            package.metadata.matlab_version = version;
            
            save(filePath, '-struct', 'package');
            Logger.getInstance().info('Model saved: %s', modelId);
            AuditLogger.getInstance().logModelTrain(modelId, metadata.params, metadata.metrics);
        end
        
        function [net, metadata] = loadModel(obj, modelId)
            filePath = fullfile(obj.artifactDir, sprintf('%s.mat', modelId));
            if ~exist(filePath, 'file')
                error('ModelManager:NotFound', 'Model %s not found', modelId);
            end
            S = load(filePath);
            net = S.net;
            metadata = S.metadata;
            Logger.getInstance().info('Model loaded: %s (trained %s)', modelId, metadata.saved_at);
        end
        
        function models = listModels(obj)
            files = dir(fullfile(obj.artifactDir, 'model_*.mat'));
            models = struct('id', {}, 'saved_at', {}, 'metrics', {});
            for i = 1:length(files)
                name = files(i).name;
                id = extractBetween(name, 1, strlength(name)-4);
                S = load(fullfile(obj.artifactDir, name), 'metadata');
                models(i).id = id;
                models(i).saved_at = S.metadata.saved_at;
                if isfield(S.metadata, 'metrics')
                    models(i).metrics = S.metadata.metrics;
                end
            end
        end
        
        function deleteModel(obj, modelId)
            filePath = fullfile(obj.artifactDir, sprintf('%s.mat', modelId));
            if exist(filePath, 'file')
                delete(filePath);
                Logger.getInstance().info('Model deleted: %s', modelId);
            end
        end
        
        function exportModel(obj, modelId, format, destination)
            [net, metadata] = obj.loadModel(modelId);
            switch lower(format)
                case 'mat'
                    copyfile(fullfile(obj.artifactDir, sprintf('%s.mat', modelId)), destination);
                case 'onnx'
                    if exist('exportONNXNetwork', 'file')
                        exportONNXNetwork(net, destination);
                    else
                        error('ModelManager:NoONNX', 'Deep Learning Toolbox required for ONNX export');
                    end
                case 'c'
                    if exist('genFunction', 'file')
                        genFunction(net, destination);
                    else
                        error('ModelManager:NoGenFunction', 'MATLAB Coder required for C export');
                    end
                otherwise
                    error('ModelManager:UnknownFormat', 'Unknown format: %s', format);
            end
            AuditLogger.getInstance().logExport(modelId, format, destination);
            Logger.getInstance().info('Model %s exported to %s as %s', modelId, destination, format);
        end
    end
end
