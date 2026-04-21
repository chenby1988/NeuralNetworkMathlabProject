classdef hyperparam_tuner < handle
    % HYPERPARAM_TUNER Automatic hyperparameter optimization
    %   Supports grid search and bayesian optimization
    
    properties
        Config struct
        Tracker experiment_tracker
        Manager model_manager
    end
    
    methods
        function obj = hyperparam_tuner(config)
            if nargin < 1
                config = ConfigManager.load();
            end
            obj.Config = config;
            obj.Tracker = experiment_tracker.getInstance();
            obj.Manager = model_manager();
        end
        
        function [bestParams, bestModel, bestMetric] = optimize(obj, X_train, Y_train, X_val, Y_val)
            searchCfg = obj.Config.hyperparam_search;
            if ~searchCfg.enabled
                bestParams = obj.getDefaultParams();
                [bestModel, bestMetric] = obj.trainAndEvaluate(bestParams, X_train, Y_train, X_val, Y_val);
                return;
            end
            
            logger = Logger.getInstance();
            logger.info('Starting hyperparameter optimization: %s', searchCfg.method);
            
            switch lower(searchCfg.method)
                case 'grid'
                    [bestParams, bestModel, bestMetric] = obj.gridSearch(searchCfg, X_train, Y_train, X_val, Y_val);
                case 'bayesian'
                    [bestParams, bestModel, bestMetric] = obj.bayesianSearch(searchCfg, X_train, Y_train, X_val, Y_val);
                case 'random'
                    [bestParams, bestModel, bestMetric] = obj.randomSearch(searchCfg, X_train, Y_train, X_val, Y_val);
                otherwise
                    error('HyperparamTuner:UnknownMethod', 'Unknown method: %s', searchCfg.method);
            end
            
            logger.info('Optimization complete. Best metric: %.6f', bestMetric);
        end
        
        function [bestParams, bestModel, bestMetric] = gridSearch(obj, searchCfg, X_train, Y_train, X_val, Y_val)
            space = searchCfg.search_space;
            hiddenOptions = space.hidden_layers;
            lrOptions = space.learning_rate;
            l2Options = space.l2_lambda;
            
            bestMetric = inf;
            bestParams = [];
            bestModel = [];
            total = length(hiddenOptions) * length(lrOptions) * length(l2Options);
            count = 0;
            
            for h = 1:length(hiddenOptions)
                for lr = 1:length(lrOptions)
                    for l2 = 1:length(l2Options)
                        count = count + 1;
                        params = struct();
                        params.hidden_layers = hiddenOptions{h};
                        params.learning_rate = lrOptions(lr);
                        params.l2_lambda = l2Options(l2);
                        
                        Logger.getInstance().info('Grid search [%d/%d]: %s', count, total, jsonencode(params));
                        [net, metric] = obj.trainAndEvaluate(params, X_train, Y_train, X_val, Y_val);
                        
                        if metric < bestMetric
                            bestMetric = metric;
                            bestParams = params;
                            bestModel = net;
                        end
                    end
                end
            end
        end
        
        function [bestParams, bestModel, bestMetric] = bayesianSearch(obj, searchCfg, X_train, Y_train, X_val, Y_val)
            % Simplified bayesian-like adaptive search using MATLAB's bayesopt if available
            if exist('bayesopt', 'file')
                [bestParams, bestModel, bestMetric] = obj.useBayesopt(searchCfg, X_train, Y_train, X_val, Y_val);
            else
                Logger.getInstance().warning('bayesopt not available, falling back to random search');
                [bestParams, bestModel, bestMetric] = obj.randomSearch(searchCfg, X_train, Y_train, X_val, Y_val);
            end
        end
        
        function [bestParams, bestModel, bestMetric] = useBayesopt(obj, searchCfg, X_train, Y_train, X_val, Y_val)
            % Define optimizable variables
            space = searchCfg.search_space;
            maxEpochs = min(searchCfg.max_iterations, 30);
            
            % Simple wrapper for bayesopt with continuous vars
            lrs = space.learning_rate;
            l2s = space.l2_lambda;
            
            optVars = [
                optimizableVariable('lr', [min(lrs), max(lrs)], 'Type', 'real')
                optimizableVariable('l2', [min(l2s), max(l2s)], 'Type', 'real')
            ];
            
            fun = @(vars) obj.objectiveWrapper(vars, X_train, Y_train, X_val, Y_val);
            results = bayesopt(fun, optVars, 'MaxObjectiveEvaluations', maxEpochs, ...
                'IsObjectiveDeterministic', false, 'Verbose', 0);
            
            bestX = results.XAtMinObjective;
            bestParams = struct();
            bestParams.hidden_layers = space.hidden_layers{1};
            if istable(bestX)
                bestParams.learning_rate = bestX{1, 'lr'};
                bestParams.l2_lambda = bestX{1, 'l2'};
            elseif isstruct(bestX)
                bestParams.learning_rate = bestX.lr;
                bestParams.l2_lambda = bestX.l2;
            elseif isnumeric(bestX) && ~isempty(bestX)
                bestParams.learning_rate = bestX(1);
                bestParams.l2_lambda = bestX(2);
            else
                error('bayesopt returned invalid XAtMinObjective type: %s', class(bestX));
            end
            
            [bestModel, bestMetric] = obj.trainAndEvaluate(bestParams, X_train, Y_train, X_val, Y_val);
        end
        
        function [bestParams, bestModel, bestMetric] = randomSearch(obj, searchCfg, X_train, Y_train, X_val, Y_val)
            space = searchCfg.search_space;
            maxIter = searchCfg.max_iterations;
            
            bestMetric = inf;
            bestParams = [];
            bestModel = [];
            
            for i = 1:maxIter
                params = struct();
                hIdx = randi(length(space.hidden_layers));
                params.hidden_layers = space.hidden_layers{hIdx};
                lrRange = space.learning_rate;
                params.learning_rate = lrRange(1) + rand() * (lrRange(end) - lrRange(1));
                l2Range = space.l2_lambda;
                params.l2_lambda = l2Range(1) + rand() * (l2Range(end) - l2Range(1));
                
                Logger.getInstance().info('Random search [%d/%d]', i, maxIter);
                [net, metric] = obj.trainAndEvaluate(params, X_train, Y_train, X_val, Y_val);
                
                if metric < bestMetric
                    bestMetric = metric;
                    bestParams = params;
                    bestModel = net;
                end
            end
        end
        
        function metric = objectiveWrapper(obj, vars, X_train, Y_train, X_val, Y_val)
            params = struct();
            cfg = ConfigManager.load();
            params.hidden_layers = cfg.model.hidden_layers;
            params.learning_rate = vars.lr;
            params.l2_lambda = vars.l2;
            [~, metric] = obj.trainAndEvaluate(params, X_train, Y_train, X_val, Y_val);
        end
        
        function [net, valMse] = trainAndEvaluate(obj, params, X_train, Y_train, X_val, Y_val)
            expId = obj.Tracker.startExperiment('feedforwardnet', params);
            tic;
            
            try
                hl = params.hidden_layers;
                if ~isrow(hl), hl = hl(:)'; end
                net = feedforwardnet(hl);
                net.trainParam.epochs = obj.Config.model.training.max_epochs;
                net.trainParam.goal = obj.Config.model.training.goal;
                net.trainParam.lr = params.learning_rate;
                net.trainFcn = obj.Config.model.training.algorithm;
                net.performParam.regularization = params.l2_lambda;
                
                % Quick train
                net = train(net, X_train', Y_train');
                Y_pred = net(X_val')';
                valMse = mean((Y_val - Y_pred).^2);
                
                obj.Tracker.finishExperiment(expId, 'completed', valMse, toc);
            catch ME
                Logger.getInstance().error('Training failed: %s', ME.message);
                obj.Tracker.finishExperiment(expId, 'failed', inf, toc);
                valMse = inf;
                net = [];
            end
        end
        
        function params = getDefaultParams(obj)
            params = struct();
            params.hidden_layers = obj.Config.model.hidden_layers;
            params.learning_rate = obj.Config.model.training.learning_rate;
            params.l2_lambda = obj.Config.model.regularization.l2_lambda;
        end
    end
end
