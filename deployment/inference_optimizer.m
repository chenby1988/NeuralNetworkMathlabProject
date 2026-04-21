classdef inference_optimizer < handle
    % INFERENCE_OPTIMIZER Optimizes model for faster prediction
    
    methods (Static)
        function fastNet = compileNetwork(net)
            % For MATLAB, compilation means generating a standalone MEX or function
            logger = Logger.getInstance();
            logger.info('Optimizing network for inference...');
            
            % Use MATLAB Coder compatible generation if available
            if exist('genFunction', 'file')
                genFile = 'artifacts/optimized_nn.m';
                genFunction(net, genFile);
                logger.info('Generated MATLAB function: %s', genFile);
            end
            
            % Return network with reduced overhead settings
            fastNet = net;
            if isprop(fastNet, 'trainFcn')
                fastNet.trainFcn = 'none'; % Disable training mode overhead
            end
            logger.info('Inference optimization complete');
        end
        
        function benchmark(net, X, iterations)
            if nargin < 3
                iterations = 100;
            end
            
            logger = Logger.getInstance();
            logger.info('Benchmarking inference: %d iterations, %d samples', iterations, size(X, 1));
            
            % Warmup
            net(X');
            
            times = zeros(iterations, 1);
            for i = 1:iterations
                tic;
                net(X');
                times(i) = toc;
            end
            
            report = struct();
            report.mean_ms = mean(times) * 1000;
            report.median_ms = median(times) * 1000;
            report.min_ms = min(times) * 1000;
            report.max_ms = max(times) * 1000;
            report.std_ms = std(times) * 1000;
            report.throughput_sps = size(X, 1) / mean(times); % samples per second
            
            logger.info('Benchmark: %.3f ms/sample (%.1f samples/sec)', ...
                report.mean_ms / size(X, 1), report.throughput_sps);
        end
    end
end
