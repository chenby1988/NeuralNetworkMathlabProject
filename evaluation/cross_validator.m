classdef cross_validator < handle
    % CROSS_VALIDATOR K-Fold cross validation with full metrics
    
    methods (Static)
        function results = kfold(X, Y, k, trainFunc, evalFunc)
            if nargin < 4
                trainFunc = @(xtr, ytr) feedforwardnet(10);
            end
            if nargin < 5
                evalFunc = @(net, xte, yte) evaluator.evaluate(yte, net(xte')');
            end
            
            logger = Logger.getInstance();
            logger.info('Starting %d-fold cross validation...', k);
            
            n = size(X, 1);
            indices = crossvalind('Kfold', n, k);
            
            foldResults = cell(k, 1);
            for fold = 1:k
                logger.info('Fold %d/%d', fold, k);
                testIdx = (indices == fold);
                trainIdx = ~testIdx;
                
                X_train = X(trainIdx, :);
                Y_train = Y(trainIdx, :);
                X_test = X(testIdx, :);
                Y_test = Y(testIdx, :);
                
                net = trainFunc(X_train, Y_train);
                net = train(net, X_train', Y_train');
                
                foldResults{fold} = evalFunc(net, X_test, Y_test);
            end
            
            % Aggregate results
            results = struct();
            results.folds = foldResults;
            results.kfold = k;
            
            metricNames = fieldnames(foldResults{1});
            for i = 1:length(metricNames)
                name = metricNames{i};
                if ischar(name) && ~ismember(name, {'residuals', 'sample_count'})
                    vals = cellfun(@(r) r.(name), foldResults);
                    results.agg.(name).mean = mean(vals);
                    results.agg.(name).std = std(vals);
                    results.agg.(name).min = min(vals);
                    results.agg.(name).max = max(vals);
                end
            end
            
            logger.info('Cross validation complete. Mean RMSE: %.6f (+/- %.6f)', ...
                results.agg.rmse.mean, results.agg.rmse.std);
        end
    end
end
