classdef ab_test_framework < handle
    % AB_TEST_FRAMEWORK Compare two models statistically
    
    methods (Static)
        function result = compare(modelA, modelB, X_test, Y_test, modelA_name, modelB_name)
            if nargin < 5
                modelA_name = 'Model A';
            end
            if nargin < 6
                modelB_name = 'Model B';
            end
            
            logger = Logger.getInstance();
            logger.info('Running A/B test: %s vs %s', modelA_name, modelB_name);
            
            predA = modelA(X_test')';
            predB = modelB(X_test')';
            
            errA = Y_test - predA;
            errB = Y_test - predB;
            
            mseA = mean(errA.^2);
            mseB = mean(errB.^2);
            
            % Paired t-test on squared errors
            seA = errA.^2;
            seB = errB.^2;
            [~, pValue] = ttest(seA, seB);
            
            result = struct();
            result.modelA_name = modelA_name;
            result.modelB_name = modelB_name;
            result.mseA = mseA;
            result.mseB = mseB;
            result.improvement = (mseA - mseB) / mseA * 100;
            result.p_value = pValue;
            result.significant = pValue < 0.05;
            
            if result.significant
                if mseB < mseA
                    winner = modelB_name;
                else
                    winner = modelA_name;
                end
                logger.info('A/B test result: %s is significantly better (p=%.4f)', winner, pValue);
            else
                logger.info('A/B test result: No significant difference (p=%.4f)', pValue);
            end
        end
        
        function fig = plotComparison(result, X_test, Y_test, modelA, modelB)
            fig = figure('Name', 'A/B Test Comparison', 'NumberTitle', 'off', 'Position', [100 100 1000 400]);
            
            predA = modelA(X_test')';
            predB = modelB(X_test')';
            
            [X_sorted, idx] = sort(X_test);
            
            subplot(1, 2, 1);
            plot(X_sorted, Y_test(idx), 'k-', 'LineWidth', 2, 'DisplayName', 'True');
            hold on;
            plot(X_sorted, predA(idx), 'b--', 'LineWidth', 1.5, 'DisplayName', result.modelA_name);
            plot(X_sorted, predB(idx), 'r-.', 'LineWidth', 1.5, 'DisplayName', result.modelB_name);
            hold off;
            xlabel('X');
            ylabel('Y');
            title('Predictions');
            legend('show');
            grid on;
            
            subplot(1, 2, 2);
            bar([result.mseA, result.mseB]);
            set(gca, 'XTickLabel', {result.modelA_name, result.modelB_name});
            ylabel('MSE');
            title(sprintf('MSE Comparison (p=%.4f)', result.p_value));
            grid on;
        end
    end
end
