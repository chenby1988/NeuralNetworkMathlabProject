classdef data_cleaner < handle
    % DATA_CLEANER Data preprocessing and cleaning
    
    methods (Static)
        function [X_clean, Y_clean, ops] = clean(X, Y, method)
            if nargin < 3 || isempty(method)
                method = 'zscore';
            end
            logger = Logger.getInstance();
            ops = {};
            
            X_clean = X;
            Y_clean = Y;
            
            % Remove rows with NaN/Inf
            valid_rows = all(isfinite(X), 2) & isfinite(Y);
            removed = sum(~valid_rows);
            if removed > 0
                X_clean = X_clean(valid_rows, :);
                Y_clean = Y_clean(valid_rows, :);
                ops{end+1} = sprintf('Removed %d rows with NaN/Inf', removed);
                logger.info('Clean: removed %d invalid rows', removed);
            end
            
            % Remove duplicate rows
            [X_unique, idx] = unique([X_clean, Y_clean], 'rows', 'stable');
            if size(X_unique, 1) < size(X_clean, 1)
                dup = size(X_clean, 1) - size(X_unique, 1);
                X_clean = X_unique(:, 1:end-1);
                Y_clean = X_unique(:, end);
                ops{end+1} = sprintf('Removed %d duplicate rows', dup);
                logger.info('Clean: removed %d duplicates', dup);
            end
            
            % Normalize/standardize
            switch lower(method)
                case 'zscore'
                    X_clean = zscore(X_clean);
                    ops{end+1} = 'Applied Z-score normalization';
                case 'minmax'
                    X_min = min(X_clean);
                    X_max = max(X_clean);
                    range = X_max - X_min;
                    range(range == 0) = 1;
                    X_clean = (X_clean - X_min) ./ range;
                    ops{end+1} = 'Applied Min-Max normalization';
                case 'none'
                    ops{end+1} = 'No normalization applied';
                otherwise
                    logger.warning('Unknown normalization method: %s', method);
            end
            
            logger.info('Data cleaning complete: %d -> %d samples', length(Y), length(Y_clean));
        end
        
        function [X_train, Y_train, X_val, Y_val, X_test, Y_test] = split(X, Y, ratios, seed)
            if nargin < 4
                seed = 42;
            end
            if nargin < 3 || isempty(ratios)
                ratios = [0.7, 0.15, 0.15];
            end
            
            rng(seed);
            n = size(X, 1);
            idx = randperm(n);
            
            n_train = round(n * ratios(1));
            n_val = round(n * ratios(2));
            
            train_idx = idx(1:n_train);
            val_idx = idx(n_train+1:n_train+n_val);
            test_idx = idx(n_train+n_val+1:end);
            
            X_train = X(train_idx, :);
            Y_train = Y(train_idx, :);
            X_val = X(val_idx, :);
            Y_val = Y(val_idx, :);
            X_test = X(test_idx, :);
            Y_test = Y(test_idx, :);
            
            Logger.getInstance().info('Data split: train=%d, val=%d, test=%d', ...
                length(train_idx), length(val_idx), length(test_idx));
        end
    end
end
