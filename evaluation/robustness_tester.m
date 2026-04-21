classdef robustness_tester < handle
    % ROBUSTNESS_TESTER Tests model stability under perturbations
    
    methods (Static)
        function report = testNoise(net, X, Y, noiseLevels)
            if nargin < 4 || isempty(noiseLevels)
                noiseLevels = [0.05, 0.1, 0.2, 0.3];
            end
            
            logger = Logger.getInstance();
            logger.info('Robustness testing with %d noise levels...', length(noiseLevels));
            
            baselinePred = net(X')';
            baselineMse = mean((Y - baselinePred).^2);
            
            report = struct();
            report.baseline_mse = baselineMse;
            report.noise_levels = noiseLevels;
            report.results = struct('level', {}, 'mse', {}, 'degradation', {});
            
            for i = 1:length(noiseLevels)
                level = noiseLevels(i);
                X_noisy = X + level * randn(size(X));
                Y_pred = net(X_noisy')';
                mse = mean((Y - Y_pred).^2);
                degradation = (mse - baselineMse) / baselineMse * 100;
                
                report.results(i).level = level;
                report.results(i).mse = mse;
                report.results(i).degradation = degradation;
                
                logger.info('Noise %.2f: MSE=%.6f (+%.1f%%)', level, mse, degradation);
            end
            
            % Stability score: average degradation
            degradations = [report.results.degradation];
            report.stability_score = max(0, 100 - mean(degradations));
            logger.info('Stability score: %.1f/100', report.stability_score);
        end
        
        function fig = plotRobustness(report)
            fig = figure('Name', 'Robustness Analysis', 'NumberTitle', 'off');
            levels = [report.results.level];
            degradations = [report.results.degradation];
            bar(levels, degradations, 'FaceColor', [0.8 0.3 0.3]);
            xlabel('Noise Level (std)');
            ylabel('Performance Degradation (%)');
            title(sprintf('Robustness Test (Stability Score: %.1f)', report.stability_score));
            grid on;
        end
    end
end
