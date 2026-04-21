classdef data_pipeline < handle
    % DATA_PIPELINE Complete ETL pipeline: Load -> Validate -> Clean -> Split -> Version
    
    properties
        Loader multi_source_loader
        Validator data_validator
        Cleaner data_cleaner
        VersionManager data_version_manager
        Config struct
        Audit AuditLogger
    end
    
    methods
        function obj = data_pipeline(config)
            if nargin < 1
                config = ConfigManager.load();
            end
            obj.Config = config;
            obj.Validator = data_validator(config);
            obj.VersionManager = data_version_manager();
            obj.Audit = AuditLogger.getInstance();
        end
        
        function result = execute(obj, sourceType, sourcePath, options)
            logger = Logger.getInstance();
            logger.info('========== DATA PIPELINE START ==========');
            tic;
            
            % 1. Load
            logger.info('Stage 1: Loading data...');
            if nargin < 4
                options = struct();
            end
            [X_raw, Y_raw, loadMeta] = multi_source_loader.load(sourceType, sourcePath, options);
            
            % 2. Validate
            logger.info('Stage 2: Validating data...');
            valReport = obj.Validator.validate(X_raw, Y_raw);
            if ~valReport.passed
                logger.error('Validation failed. Aborting pipeline.');
                error('Pipeline:ValidationFailed', 'Data validation failed.');
            end
            
            % 3. Clean
            logger.info('Stage 3: Cleaning data...');
            normMethod = ConfigManager.get(obj.Config, 'data.validation.normalize_method', 'zscore');
            [X_clean, Y_clean, cleanOps] = data_cleaner.clean(X_raw, Y_raw, normMethod);
            
            % 4. Split
            logger.info('Stage 4: Splitting data...');
            splitCfg = obj.Config.data.split;
            ratios = [splitCfg.train_ratio, splitCfg.val_ratio, splitCfg.test_ratio];
            [X_train, Y_train, X_val, Y_val, X_test, Y_test] = ...
                data_cleaner.split(X_clean, Y_clean, ratios, splitCfg.random_seed);
            
            % 5. Version
            logger.info('Stage 5: Versioning data...');
            versionMeta = struct();
            versionMeta.source = loadMeta;
            versionMeta.validation = valReport.stats;
            versionMeta.cleaning_ops = cleanOps;
            versionMeta.split_ratios = ratios;
            versionId = obj.VersionManager.saveVersion(X_clean, Y_clean, versionMeta);
            
            elapsed = toc;
            logger.info('========== DATA PIPELINE END (%.2fs) ==========', elapsed);
            
            % Assemble result
            result = struct();
            result.X_train = X_train;
            result.Y_train = Y_train;
            result.X_val = X_val;
            result.Y_val = Y_val;
            result.X_test = X_test;
            result.Y_test = Y_test;
            result.validation_report = valReport;
            result.cleaning_operations = cleanOps;
            result.version_id = versionId;
            result.metadata = versionMeta;
            
            obj.Audit.logDataAccess(sourceType, size(X_clean, 1), 'PIPELINE_COMPLETE');
        end
    end
end
