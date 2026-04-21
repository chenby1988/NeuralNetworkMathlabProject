classdef experiment_tracker < handle
    % EXPERIMENT_TRACKER Tracks all experiments with parameters and metrics
    %   Uses struct array instead of table to avoid type conversion issues
    
    properties (Access = private)
        dbPath char
        experiments struct
    end
    
    methods (Static)
        function obj = getInstance()
            persistent instance
            if isempty(instance) || ~isvalid(instance)
                instance = experiment_tracker();
            end
            obj = instance;
        end
    end
    
    methods (Access = private)
        function obj = experiment_tracker()
            obj.dbPath = 'artifacts/experiments.mat';
            if exist(obj.dbPath, 'file')
                S = load(obj.dbPath);
                obj.experiments = S.experiments;
            else
                obj.experiments = struct('exp_id', {}, 'status', {}, 'model_type', {}, ...
                    'params_json', {}, 'best_metric', {}, 'duration', {}, 'created_at', {});
            end
        end
        
        function saveDb(obj)
            experiments = obj.experiments;
            save(obj.dbPath, 'experiments');
        end
    end
    
    methods
        function expId = startExperiment(obj, modelType, params)
            expId = sprintf('exp_%s_%04X', datestr(now, 'yyyymmdd_HHMMSS'), randi(65535));
            paramsJson = jsonencode(params);
            
            newExp = struct();
            newExp.exp_id = expId;
            newExp.status = 'running';
            newExp.model_type = modelType;
            newExp.params_json = paramsJson;
            newExp.best_metric = NaN;
            newExp.duration = NaN;
            newExp.created_at = datestr(now);
            
            obj.experiments = [obj.experiments, newExp];
            obj.saveDb();
            Logger.getInstance().info('Experiment started: %s', expId);
        end
        
        function finishExperiment(obj, expId, status, bestMetric, duration)
            for i = 1:length(obj.experiments)
                if strcmp(obj.experiments(i).exp_id, expId)
                    obj.experiments(i).status = status;
                    obj.experiments(i).best_metric = bestMetric;
                    obj.experiments(i).duration = duration;
                    obj.saveDb();
                    break;
                end
            end
            Logger.getInstance().info('Experiment %s finished: status=%s, metric=%.6f', expId, status, bestMetric);
        end
        
        function best = getBestExperiment(obj, ~)
            best = [];
            if isempty(obj.experiments)
                return;
            end
            statuses = {obj.experiments.status};
            completed = obj.experiments(strcmp(statuses, 'completed'));
            if isempty(completed)
                return;
            end
            metrics = [completed.best_metric];
            [~, idx] = min(metrics);
            best = completed(idx);
        end
        
        function compareResult = compareExperiments(obj, expIds)
            ids = {obj.experiments.exp_id};
            mask = ismember(ids, expIds);
            compareResult = obj.experiments(mask);
        end
        
        function all = listAll(obj)
            all = obj.experiments;
        end
    end
end
