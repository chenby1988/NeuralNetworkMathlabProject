classdef evaluator < handle
    % EVALUATOR Comprehensive multi-dimensional evaluation metrics
    
    methods (Static)
        function report = evaluate(Y_true, Y_pred, metrics)
            if nargin < 3 || isempty(metrics)
                metrics = {'mse', 'rmse', 'mae', 'r2', 'mape'};
            end
            
            report = struct();
            report.sample_count = length(Y_true);
            
            residuals = Y_true - Y_pred;
            report.residuals = residuals;
            
            for i = 1:length(metrics)
                metric = lower(metrics{i});
                switch metric
                    case 'mse'
                        report.mse = mean(residuals.^2);
                    case 'rmse'
                        report.rmse = sqrt(mean(residuals.^2));
                    case 'mae'
                        report.mae = mean(abs(residuals));
                    case 'r2'
                        ss_res = sum(residuals.^2);
                        ss_tot = sum((Y_true - mean(Y_true)).^2);
                        report.r2 = 1 - ss_res / ss_tot;
                    case 'mape'
                        report.mape = mean(abs(residuals ./ Y_true)) * 100;
                    case 'explained_variance'
                        report.explained_variance = 1 - var(residuals) / var(Y_true);
                    case 'max_error'
                        report.max_error = max(abs(residuals));
                    case 'median_ae'
                        report.median_ae = median(abs(residuals));
                end
            end
            
            % Distribution stats
            report.residual_mean = mean(residuals);
            report.residual_std = std(residuals);
            report.residual_skewness = skewness(residuals);
            report.residual_kurtosis = kurtosis(residuals);
            
            Logger.getInstance().info('Evaluation complete: RMSE=%.6f, R2=%.6f', report.rmse, report.r2);
        end
        
        function fig = plotAnalysis(Y_true, Y_pred, titleStr)
            if nargin < 3
                titleStr = 'Model Analysis';
            end
            fig = figure('Name', titleStr, 'NumberTitle', 'off', 'Position', [100 100 1200 400]);
            
            % Subplot 1: Prediction vs Actual
            subplot(1, 3, 1);
            scatter(Y_true, Y_pred, 15, 'b', 'filled');
            hold on;
            minVal = min([Y_true; Y_pred]);
            maxVal = max([Y_true; Y_pred]);
            plot([minVal, maxVal], [minVal, maxVal], 'r--', 'LineWidth', 2);
            hold off;
            xlabel('Actual');
            ylabel('Predicted');
            title('Prediction vs Actual');
            grid on;
            axis equal;
            
            % Subplot 2: Residuals
            subplot(1, 3, 2);
            residuals = Y_true - Y_pred;
            scatter(Y_pred, residuals, 15, 'g', 'filled');
            hold on;
            plot([min(Y_pred), max(Y_pred)], [0, 0], 'r--');
            hold off;
            xlabel('Predicted');
            ylabel('Residual');
            title('Residual Plot');
            grid on;
            
            % Subplot 3: Error Distribution
            subplot(1, 3, 3);
            histogram(residuals, 30, 'FaceColor', [0.3 0.5 0.8], 'EdgeColor', 'none');
            xlabel('Residual');
            ylabel('Frequency');
            title('Error Distribution');
            grid on;
        end
    end
end
