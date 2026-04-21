classdef test_core < matlab.unittest.TestCase
    % TEST_CORE Unit tests for core infrastructure modules
    
    methods (Test)
        function testConfigLoad(testCase)
            cfg = ConfigManager.load('config/system_config.json');
            testCase.verifyTrue(isstruct(cfg));
            testCase.verifyEqual(cfg.system.name, 'NN_Sim_Pro');
        end
        
        function testConfigGetNested(testCase)
            cfg = ConfigManager.load();
            val = ConfigManager.get(cfg, 'model.hidden_layers');
            testCase.verifyTrue(iscell(val) || isnumeric(val));
        end
        
        function testLoggerSingleton(testCase)
            l1 = Logger.getInstance();
            l2 = Logger.getInstance();
            testCase.verifySameHandle(l1, l2);
        end
        
        function testExceptionHandlerFallback(testCase)
            badFunc = @() error('test');
            result = ExceptionHandler.safeExecuteWithFallback(badFunc, 42);
            testCase.verifyEqual(result, 42);
        end
        
        function testAuditLogCreation(testCase)
            audit = AuditLogger.getInstance();
            testCase.verifyTrue(isvalid(audit));
        end
        
        function testValidateNotEmpty(testCase)
            testCase.verifyError(@() ExceptionHandler.validateNotEmpty([], 'x'), ...
                'ValidationError:Empty');
        end
        
        function testValidateRange(testCase)
            testCase.verifyError(@() ExceptionHandler.validateRange(5, 0, 3, 'x'), ...
                'ValidationError:OutOfRange');
        end
    end
end
