classdef test_models < matlab.unittest.TestCase
    % TEST_MODELS Unit tests for model management
    
    methods (Test)
        function testExperimentTracker(testCase)
            tracker = experiment_tracker.getInstance();
            expId = tracker.startExperiment('test', struct('lr', 0.01));
            testCase.verifyTrue(~isempty(expId));
            tracker.finishExperiment(expId, 'completed', 0.01, 1.0);
            best = tracker.getBestExperiment();
            testCase.verifyTrue(~isempty(best));
        end
        
        function testModelManagerSaveLoad(testCase)
            net = feedforwardnet(5);
            mgr = model_manager();
            meta = struct('params', struct(), 'metrics', struct('mse', 0.01));
            modelId = mgr.saveModel(net, meta);
            testCase.verifyTrue(~isempty(modelId));
            
            [loadedNet, loadedMeta] = mgr.loadModel(modelId);
            testCase.verifyTrue(isa(loadedNet, 'network'));
            mgr.deleteModel(modelId);
        end
    end
end
