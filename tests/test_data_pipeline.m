classdef test_data_pipeline < matlab.unittest.TestCase
    % TEST_DATA_PIPELINE Unit tests for data pipeline modules
    
    methods (Test)
        function testSyntheticGeneration(testCase)
            [X, Y, meta] = multi_source_loader.load('generator', '', struct('N', 100, 'func', 'sin'));
            testCase.verifySize(X, [100 1]);
            testCase.verifySize(Y, [100 1]);
            testCase.verifyEqual(meta.function, 'sin');
        end
        
        function testDataValidation(testCase)
            X = randn(100, 3);
            Y = sin(X(:,1));
            validator = data_validator();
            report = validator.validate(X, Y);
            testCase.verifyTrue(report.passed);
        end
        
        function testDataCleaning(testCase)
            X = [1; 2; NaN; 4; 5];
            Y = [1; 2; 3; 4; 5];
            [Xc, Yc, ops] = data_cleaner.clean(X, Y, 'none');
            testCase.verifyEqual(length(Yc), 4);
            testCase.verifyTrue(contains(ops{1}, 'Removed'));
        end
        
        function testDataSplit(testCase)
            X = randn(100, 2);
            Y = randn(100, 1);
            [Xt, Yt, Xv, Yv, Xte, Yte] = data_cleaner.split(X, Y, [0.6, 0.2, 0.2], 42);
            testCase.verifyEqual(size(Xt,1) + size(Xv,1) + size(Xte,1), 100);
        end
        
        function testPipelineExecution(testCase)
            pipeline = data_pipeline();
            result = pipeline.execute('generator', '', struct('N', 200, 'noise_level', 0.1));
            testCase.verifyTrue(isfield(result, 'X_train'));
            testCase.verifyTrue(isfield(result, 'version_id'));
            testCase.verifyTrue(~isempty(result.version_id));
        end
    end
end
