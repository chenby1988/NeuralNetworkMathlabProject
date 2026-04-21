classdef TestLoggerPlugin < matlab.unittest.plugins.TestRunnerPlugin
    % TESTLOGGERPLUGIN Logs test execution to system logger
    
    properties
        Logger
    end
    
    methods
        function obj = TestLoggerPlugin(logger)
            obj.Logger = logger;
        end
    end
    
    methods (Access = protected)
        function runTest(plugin, pluginData)
            plugin.Logger.debug('Running test: %s', pluginData.Name);
            runTest@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end
        
        function testCaseSuccess(plugin, pluginData)
            plugin.Logger.debug('PASSED: %s', pluginData.Name);
            testCaseSuccess@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end
        
        function testCaseFailure(plugin, pluginData)
            plugin.Logger.error('FAILED: %s - %s', pluginData.Name, pluginData.TestDiagnostic.DiagnosticResult);
            testCaseFailure@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end
    end
end
