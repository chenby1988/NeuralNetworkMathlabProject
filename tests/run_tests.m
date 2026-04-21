function results = run_tests(filter)
    % RUN_TESTS Execute all unit tests for the NN simulation system
    %   filter: optional string to match test names
    %
    %   Usage: run_tests          % Run all tests
    %          run_tests('core')   % Run core module tests only
    
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    subfolders = {'core', 'data', 'models', 'training', 'evaluation', 'gui', 'reports', 'deployment', 'security', 'tests'};
    for i = 1:length(subfolders)
        folder = fullfile(projectRoot, subfolders{i});
        if exist(folder, 'dir') && ~contains(path, folder)
            addpath(folder);
        end
    end
    
    if nargin < 1
        filter = '';
    end
    
    logger = Logger.getInstance();
    logger.info('========== TEST SUITE START ==========');
    
    suite = matlab.unittest.TestSuite.fromFolder('tests', 'IncludingSubfolders', true);
    
    if ~isempty(filter)
        suite = suite.selectIf(matlab.unittest.selectors.HasName(ContainsSubstring(filter)));
    end
    
    runner = matlab.unittest.TestRunner.withTextOutput('Verbosity', 3);
    
    % Add custom plugin for logging
    plugin = TestLoggerPlugin(logger);
    runner.addPlugin(plugin);
    
    results = runner.run(suite);
    
    passed = sum([results.Passed]);
    failed = sum([results.Failed]);
    incomplete = sum([results.Incomplete]);
    
    logger.info('========== TEST SUITE END ==========');
    logger.info('Results: %d passed, %d failed, %d incomplete', passed, failed, incomplete);
    
    if failed > 0
        error('TestSuite:Failures', '%d test(s) failed.', failed);
    end
end
