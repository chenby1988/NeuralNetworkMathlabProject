classdef data_validator < handle
    % DATA_VALIDATOR Validates data quality before training
    
    properties
        Config struct
    end
    
    methods
        function obj = data_validator(config)
            if nargin < 1
                config = ConfigManager.load();
            end
            obj.Config = config;
        end
        
        function report = validate(obj, X, Y)
            logger = Logger.getInstance();
            report = struct();
            report.passed = true;
            report.warnings = {};
            report.errors = {};
            report.stats = struct();
            
            valCfg = obj.Config.data.validation;
            
            % Check dimensions match
            if size(X, 1) ~= size(Y, 1)
                report.passed = false;
                report.errors{end+1} = 'X and Y have different number of rows.';
                logger.error('Validation failed: dimension mismatch');
                return;
            end
            
            n = size(X, 1);
            report.stats.n_samples = n;
            report.stats.n_features = size(X, 2);
            
            % Check minimum samples
            if n < valCfg.min_samples
                report.passed = false;
                report.errors{end+1} = sprintf('Too few samples: %d < %d', n, valCfg.min_samples);
            end
            
            % Check maximum samples
            if n > valCfg.max_samples
                report.warnings{end+1} = sprintf('Large dataset: %d > %d, may be slow', n, valCfg.max_samples);
            end
            
            % Check missing values
            if valCfg.check_missing
                missingX = sum(isnan(X(:))) + sum(isinf(X(:)));
                missingY = sum(isnan(Y(:))) + sum(isinf(Y(:)));
                report.stats.missing_count = missingX + missingY;
                if missingX + missingY > 0
                    report.warnings{end+1} = sprintf('Found %d missing/inf values.', missingX + missingY);
                    logger.warning('Data has %d missing/inf values', missingX + missingY);
                end
            end
            
            % Check outliers
            if valCfg.check_outliers && n > 10
                threshold = valCfg.outlier_threshold;
                zY = zscore(Y);
                outliers = sum(abs(zY) > threshold);
                report.stats.outlier_count = outliers;
                if outliers > 0
                    report.warnings{end+1} = sprintf('Found %d outliers (|z| > %.1f).', outliers, threshold);
                    logger.warning('Data has %d outliers', outliers);
                end
            end
            
            % Check target variance
            if var(Y) < eps
                report.passed = false;
                report.errors{end+1} = 'Target variable Y has zero variance.';
            end
            
            % Summary
            report.stats.x_mean = mean(X);
            report.stats.x_std = std(X);
            report.stats.y_mean = mean(Y);
            report.stats.y_std = std(Y);
            report.stats.y_range = [min(Y), max(Y)];
            
            if report.passed
                logger.info('Data validation passed. Samples: %d, Features: %d', ...
                    report.stats.n_samples, report.stats.n_features);
            else
                logger.error('Data validation failed with %d errors.', length(report.errors));
            end
        end
    end
end
