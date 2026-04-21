% MAIN - Commercial-grade Neural Network Simulation & Analysis System
%   Usage: In VS Code, press Ctrl+F5 to run directly
%
%   This script runs the complete workflow:
%   Data Pipeline -> Hyperparam Search -> Training -> Evaluation -> Report

clear classes;
%% ========================================================================
% AUTO-SETUP: Add all subfolders to MATLAB path
% ========================================================================
scriptPath = mfilename('fullpath');
if isempty(scriptPath)
    projectRoot = pwd;
else
    projectRoot = fileparts(scriptPath);
end
subfolders = {'core', 'data', 'models', 'training', 'evaluation', 'gui', 'reports', 'deployment', 'security', 'tests'};
for i = 1:length(subfolders)
    folder = fullfile(projectRoot, subfolders{i});
    if exist(folder, 'dir') && ~contains(path, folder)
        addpath(folder);
    end
end
clearvars scriptPath projectRoot subfolders i folder
close all;

%% ========================================================================
% PHASE 0: System Initialization
% ========================================================================
cfg = ConfigManager.load('config/system_config.json');
logger = Logger.getInstance('config/system_config.json');
audit = AuditLogger.getInstance();

logger.info('=================================================');
logger.info('  NN SIMULATION PRO v%s - System Startup', cfg.system.version);
logger.info('=================================================');
audit.log('SYSTEM_START', struct('version', cfg.system.version));

try
    %% ========================================================================
    % PHASE 1: Data Pipeline (ETL + Validation + Cleaning + Versioning)
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 1: DATA PIPELINE');
    
    pipeline = data_pipeline(cfg);
    dataResult = pipeline.execute('generator', '', struct('N', 1000, 'noise_level', 0.15, 'func', 'complex'));
    
    X_train = dataResult.X_train;
    Y_train = dataResult.Y_train;
    X_val = dataResult.X_val;
    Y_val = dataResult.Y_val;
    X_test = dataResult.X_test;
    Y_test = dataResult.Y_test;
    
    logger.info('Data version: %s', dataResult.version_id);
    
    %% ========================================================================
    % PHASE 2: Hyperparameter Optimization
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 2: HYPERPARAMETER OPTIMIZATION');
    
    tuner = hyperparam_tuner(cfg);
    [bestParams, bestNet, bestMetric] = tuner.optimize(X_train, Y_train, X_val, Y_val);
    
    logger.info('Best params: hidden=%s, lr=%.4f, l2=%.6f', ...
        mat2str(bestParams.hidden_layers), bestParams.learning_rate, bestParams.l2_lambda);
    
    %% ========================================================================
    % PHASE 3: Advanced Training (Checkpointing + Early Stopping + LR Schedule)
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 3: ADVANCED TRAINING');
    
    net = feedforwardnet(bestParams.hidden_layers);
    net.trainParam.epochs = cfg.model.training.max_epochs;
    net.trainParam.goal = cfg.model.training.goal;
    net.trainParam.lr = bestParams.learning_rate;
    net.trainFcn = cfg.model.training.algorithm;
    net = regularization.applyL2(net, bestParams.l2_lambda);
    
    trainerEngine = trainer(cfg);
    trainerEngine.clearCheckpoints();
    [net, trainInfo] = trainerEngine.train(net, X_train, Y_train, X_val, Y_val);
    
    %% ========================================================================
    % PHASE 4: Model Versioning & Export
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 4: MODEL VERSIONING');
    
    mgr = model_manager();
    modelMeta = struct();
    modelMeta.params = bestParams;
    modelMeta.metrics = struct('val_loss', trainInfo.best_val_loss);
    modelMeta.train_info = trainInfo;
    modelMeta.data_version = dataResult.version_id;
    modelId = mgr.saveModel(net, modelMeta);
    
    %% ========================================================================
    % PHASE 5: Multi-Dimensional Evaluation
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 5: EVALUATION');
    
    Y_pred = net(X_test')';
    evalReport = evaluator.evaluate(Y_test, Y_pred, cfg.evaluation.metrics);
    
    if cfg.evaluation.cross_validation.enabled
        logger.info('Running cross-validation...');
        cvResults = cross_validator.kfold([X_train; X_val], [Y_train; Y_val], ...
            cfg.evaluation.cross_validation.k_folds);
        logger.info('CV Mean RMSE: %.6f (+/- %.6f)', cvResults.agg.rmse.mean, cvResults.agg.rmse.std);
    end
    
    if cfg.evaluation.robustness.enabled
        logger.info('Running robustness tests...');
        robustReport = robustness_tester.testNoise(net, X_test, Y_test, cfg.evaluation.robustness.noise_levels);
    end
    
    %% ========================================================================
    % PHASE 6: Visualization
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 6: VISUALIZATION');
    
    [X_plot, idx] = sort(X_test);
    Y_plot_true = Y_test(idx);
    Y_plot_pred = Y_pred(idx);
    
    figure('Name', 'Final Results', 'NumberTitle', 'off', 'Position', [100 100 1200 500]);
    subplot(1, 2, 1);
    plot(X_plot, Y_plot_true, 'k-', 'LineWidth', 2); hold on;
    plot(X_plot, Y_plot_pred, 'r--', 'LineWidth', 1.5);
    scatter(X_test, Y_test, 10, 'b', 'filled');
    hold off; xlabel('X'); ylabel('Y');
    title('Model Fit'); legend('True', 'Predicted', 'Data'); grid on;
    
    subplot(1, 2, 2);
    semilogy(trainInfo.history.epoch, trainInfo.history.train_loss, 'b-', 'LineWidth', 1.5); hold on;
    semilogy(trainInfo.history.epoch, trainInfo.history.val_loss, 'r--', 'LineWidth', 1.5);
    xlabel('Epoch'); ylabel('MSE'); title('Training History');
    legend('Train', 'Val'); grid on;
    
    %% ========================================================================
    % PHASE 7: Report Generation
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 7: REPORT GENERATION');
    
    reportData = struct();
    reportData.config = struct('model_type', 'feedforwardnet', ...
        'hidden_layers', bestParams.hidden_layers, ...
        'algorithm', cfg.model.training.algorithm);
    reportData.train_info = trainInfo;
    reportData.metrics = evalReport;
    reportData.evaluation = struct('y_true', Y_test, 'y_pred', Y_pred);
    reportData.history = trainInfo.history;
    
    reportPath = fullfile(cfg.system.report_dir, sprintf('report_%s.pdf', datestr(now, 'yyyymmdd_HHMMSS')));
    report_generator.generate(reportData, reportPath);
    
    %% ========================================================================
    % PHASE 8: Deployment Preparation
    %% ========================================================================
    logger.info('');
    logger.info('>>> PHASE 8: DEPLOYMENT PREP');
    
    api = model_api(modelId);
    testPred = api.predict(X_test(1:5, :));
    logger.info('API test prediction: %s', mat2str(testPred', 3));
    
    inference_optimizer.benchmark(net, X_test, 50);
    
    %% ========================================================================
    % PHASE 9: Monitoring
    %% ========================================================================
    mon = monitor();
    mon.check(evalReport.mse, 5.0, 0.0);
    
    %% ========================================================================
    % Completion
    %% ========================================================================
    logger.info('');
    logger.info('=================================================');
    logger.info('  ALL PHASES COMPLETED SUCCESSFULLY');
    logger.info('  Model ID: %s', modelId);
    logger.info('  Test RMSE: %.6f | R2: %.6f', evalReport.rmse, evalReport.r2);
    logger.info('  Report: %s', reportPath);
    logger.info('=================================================');
    audit.log('SYSTEM_COMPLETE', struct('model_id', modelId, 'rmse', evalReport.rmse));
    
catch ME
    logger.critical('System failure: %s', ME.message);
    for k = 1:length(ME.stack)
        logger.critical('  at %s (line %d)', ME.stack(k).name, ME.stack(k).line);
    end
    audit.log('SYSTEM_ERROR', struct('message', ME.message));
    rethrow(ME);
end
