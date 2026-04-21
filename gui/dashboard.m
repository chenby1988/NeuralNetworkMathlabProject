classdef dashboard < handle
    % DASHBOARD Real-time training monitoring dashboard
    
    properties
        Fig handle
        Axes struct
        Lines struct
        UpdateInterval double
        LastUpdate double
        IsRunning logical
    end
    
    methods
        function obj = dashboard()
            obj.UpdateInterval = 2;
            obj.LastUpdate = 0;
            obj.IsRunning = true;
            obj.createUI();
        end
        
        function createUI(obj)
            obj.Fig = figure('Name', 'NN Training Dashboard', ...
                'NumberTitle', 'off', ...
                'Position', [50 50 1400 800], ...
                'CloseRequestFcn', @(~,~) obj.close());
            
            % Loss curve
            obj.Axes.loss = subplot(2, 3, 1, 'Parent', obj.Fig);
            title(obj.Axes.loss, 'Training Loss');
            xlabel(obj.Axes.loss, 'Epoch');
            ylabel(obj.Axes.loss, 'MSE (log)');
            grid(obj.Axes.loss, 'on');
            hold(obj.Axes.loss, 'on');
            obj.Lines.trainLoss = plot(obj.Axes.loss, NaN, NaN, 'b-', 'LineWidth', 1.5);
            obj.Lines.valLoss = plot(obj.Axes.loss, NaN, NaN, 'r--', 'LineWidth', 1.5);
            legend(obj.Axes.loss, {'Train', 'Validation'}, 'Location', 'best');
            set(obj.Axes.loss, 'YScale', 'log');
            
            % Learning rate
            obj.Axes.lr = subplot(2, 3, 2, 'Parent', obj.Fig);
            title(obj.Axes.lr, 'Learning Rate');
            xlabel(obj.Axes.lr, 'Epoch');
            ylabel(obj.Axes.lr, 'LR');
            grid(obj.Axes.lr, 'on');
            hold(obj.Axes.lr, 'on');
            obj.Lines.lr = plot(obj.Axes.lr, NaN, NaN, 'g-', 'LineWidth', 1.5);
            
            % Residuals
            obj.Axes.residual = subplot(2, 3, 3, 'Parent', obj.Fig);
            title(obj.Axes.residual, 'Residual Distribution');
            obj.Lines.residualHist = histogram(obj.Axes.residual, NaN, 'FaceColor', [0.3 0.5 0.8]);
            
            % Prediction vs Actual
            obj.Axes.pred = subplot(2, 3, 4, 'Parent', obj.Fig);
            title(obj.Axes.pred, 'Prediction vs Actual');
            xlabel(obj.Axes.pred, 'Actual');
            ylabel(obj.Axes.pred, 'Predicted');
            grid(obj.Axes.pred, 'on');
            hold(obj.Axes.pred, 'on');
            obj.Lines.predScatter = scatter(obj.Axes.pred, NaN, NaN, 10, 'b', 'filled');
            obj.Lines.predLine = plot(obj.Axes.pred, [0 1], [0 1], 'r--');
            
            % Fit curve
            obj.Axes.fit = subplot(2, 3, 5, 'Parent', obj.Fig);
            title(obj.Axes.fit, 'Model Fit');
            xlabel(obj.Axes.fit, 'X');
            ylabel(obj.Axes.fit, 'Y');
            grid(obj.Axes.fit, 'on');
            hold(obj.Axes.fit, 'on');
            obj.Lines.trueCurve = plot(obj.Axes.fit, NaN, NaN, 'k-', 'LineWidth', 2);
            obj.Lines.predCurve = plot(obj.Axes.fit, NaN, NaN, 'r--', 'LineWidth', 1.5);
            legend(obj.Axes.fit, {'True', 'Predicted'}, 'Location', 'best');
            
            % Metrics table
            obj.Axes.metrics = subplot(2, 3, 6, 'Parent', obj.Fig);
            axis(obj.Axes.metrics, 'off');
            obj.Lines.metricsText = text(obj.Axes.metrics, 0.1, 0.9, 'Initializing...', ...
                'FontName', 'Consolas', 'FontSize', 11, 'VerticalAlignment', 'top');
        end
        
        function update(obj, epoch, trainLoss, valLoss, lr, Y_true, Y_pred, X_sorted, Y_true_sorted, Y_pred_sorted)
            if ~isvalid(obj.Fig) || ~obj.IsRunning
                return;
            end
            if toc < obj.LastUpdate + obj.UpdateInterval
                return;
            end
            obj.LastUpdate = tic;
            
            % Update loss
            set(obj.Lines.trainLoss, 'XData', 1:epoch, 'YData', trainLoss);
            set(obj.Lines.valLoss, 'XData', 1:epoch, 'YData', valLoss);
            
            % Update LR
            set(obj.Lines.lr, 'XData', 1:epoch, 'YData', lr);
            
            % Update residuals
            residuals = Y_true - Y_pred;
            delete(obj.Lines.residualHist);
            obj.Lines.residualHist = histogram(obj.Axes.residual, residuals, 20, ...
                'FaceColor', [0.3 0.5 0.8], 'EdgeColor', 'none');
            
            % Update pred vs actual
            set(obj.Lines.predScatter, 'XData', Y_true, 'YData', Y_pred);
            lims = [min([Y_true; Y_pred]), max([Y_true; Y_pred])];
            set(obj.Lines.predLine, 'XData', lims, 'YData', lims);
            set(obj.Axes.pred, 'XLim', lims, 'YLim', lims);
            
            % Update fit
            set(obj.Lines.trueCurve, 'XData', X_sorted, 'YData', Y_true_sorted);
            set(obj.Lines.predCurve, 'XData', X_sorted, 'YData', Y_pred_sorted);
            
            % Update metrics text
            mse = mean(residuals.^2);
            rmse = sqrt(mse);
            mae = mean(abs(residuals));
            ss_res = sum(residuals.^2);
            ss_tot = sum((Y_true - mean(Y_true)).^2);
            r2 = 1 - ss_res / ss_tot;
            
            metricsStr = sprintf(['Epoch:     %d\n' ...
                'Train MSE: %.6f\n' ...
                'Val MSE:   %.6f\n' ...
                'RMSE:      %.6f\n' ...
                'MAE:       %.6f\n' ...
                'R2:        %.6f\n' ...
                'LR:        %.6f'], ...
                epoch, trainLoss(end), valLoss(end), rmse, mae, r2, lr(end));
            set(obj.Lines.metricsText, 'String', metricsStr);
            
            drawnow limitrate;
        end
        
        function close(obj)
            obj.IsRunning = false;
            if isvalid(obj.Fig)
                delete(obj.Fig);
            end
        end
    end
end
