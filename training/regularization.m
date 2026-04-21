classdef regularization < handle
    % REGULARIZATION Applies regularization techniques to network
    
    methods (Static)
        function net = applyL2(net, lambda)
            % Apply L2 weight decay via performParam
            if nargin < 2 || lambda <= 0
                return;
            end
            if isprop(net, 'performParam') && isstruct(net.performParam)
                net.performParam.regularization = lambda;
            end
            Logger.getInstance().debug('L2 regularization applied: lambda=%.6f', lambda);
        end
        
        function net = applyEarlyStopping(net, patience, minDelta)
            % Configure early stopping
            if nargin < 2
                patience = 20;
            end
            if nargin < 3
                minDelta = 1e-5;
            end
            % MATLAB's trainlm uses validation checks; we implement custom early stopping
            % in the trainer class. This is a placeholder for network-level config.
            Logger.getInstance().debug('Early stopping configured: patience=%d, minDelta=%.6f', patience, minDelta);
        end
        
        function augmentedX = augmentData(X, noiseStd)
            % Data augmentation by adding Gaussian noise
            if nargin < 2 || noiseStd <= 0
                augmentedX = X;
                return;
            end
            augmentedX = X + noiseStd * randn(size(X));
        end
        
        function net = applyDropout(net, rate)
            % Note: Standard MATLAB feedforwardnet doesn't support dropout natively.
            % This is a placeholder for compatibility with custom networks.
            if rate > 0
                Logger.getInstance().warning('Dropout not supported in feedforwardnet. Consider using layerGraph.');
            end
        end
    end
end
