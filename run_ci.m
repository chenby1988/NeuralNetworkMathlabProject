function run_ci()
    % RUN_CI Continuous Integration automation script
    %   Runs tests, validates config, checks artifacts
    
    projectRoot = fileparts(mfilename('fullpath'));
    subfolders = {'core', 'data', 'models', 'training', 'evaluation', 'gui', 'reports', 'deployment', 'security', 'tests'};
    for i = 1:length(subfolders)
        folder = fullfile(projectRoot, subfolders{i});
        if exist(folder, 'dir') && ~contains(path, folder)
            addpath(folder);
        end
    end
    
    clc;
    fprintf('========================================\n');
    fprintf('  NN SIM PRO - CI PIPELINE\n');
    fprintf('========================================\n\n');
    
    exitCode = 0;
    
    %% Step 1: Config validation
    fprintf('[CI] Step 1: Validating configuration...\n');
    try
        cfg = ConfigManager.load('config/system_config.json');
        assert(isfield(cfg, 'system'), 'Missing system section');
        assert(isfield(cfg, 'model'), 'Missing model section');
        fprintf('[CI] Config OK\n');
    catch ME
        fprintf('[CI] FAIL: %s\n', ME.message);
        exitCode = 1;
    end
    
    %% Step 2: Unit tests
    fprintf('\n[CI] Step 2: Running unit tests...\n');
    try
        results = run_tests();
        passed = sum([results.Passed]);
        failed = sum([results.Failed]);
        fprintf('[CI] Tests: %d passed, %d failed\n', passed, failed);
        if failed > 0
            exitCode = 2;
        end
    catch ME
        fprintf('[CI] FAIL: %s\n', ME.message);
        exitCode = 2;
    end
    
    %% Step 3: Directory structure check
    fprintf('\n[CI] Step 3: Checking directory structure...\n');
    requiredDirs = {'config', 'core', 'data', 'models', 'training', 'evaluation', ...
        'gui', 'reports', 'deployment', 'security', 'tests', 'logs', 'artifacts'};
    allOk = true;
    for i = 1:length(requiredDirs)
        if ~exist(requiredDirs{i}, 'dir')
            fprintf('[CI] MISSING DIR: %s\n', requiredDirs{i});
            allOk = false;
        end
    end
    if allOk
        fprintf('[CI] Directory structure OK\n');
    else
        exitCode = 3;
    end
    
    %% Summary
    fprintf('\n========================================\n');
    if exitCode == 0
        fprintf('  CI PASSED - All checks green\n');
    else
        fprintf('  CI FAILED - Exit code: %d\n', exitCode);
    end
    fprintf('========================================\n');
end
