classdef monitor < handle
    % MONITOR Simple monitoring and alerting for deployed models
    
    properties
        AlertThreshold struct
        MetricsHistory table
    end
    
    methods
        function obj = monitor()
            obj.AlertThreshold = struct('mse', 0.1, 'latency_ms', 100, 'error_rate', 0.05);
            obj.MetricsHistory = table('Size', [0 4], ...
                'VariableTypes', {'datetime', 'double', 'double', 'double'}, ...
                'VariableNames', {'timestamp', 'mse', 'latency_ms', 'error_rate'});
        end
        
        function check(obj, mse, latency_ms, error_rate)
            logger = Logger.getInstance();
            alerts = {};
            
            if mse > obj.AlertThreshold.mse
                alerts{end+1} = sprintf('HIGH_MSE: %.4f > threshold %.4f', mse, obj.AlertThreshold.mse);
            end
            if latency_ms > obj.AlertThreshold.latency_ms
                alerts{end+1} = sprintf('HIGH_LATENCY: %.1f ms > threshold %.1f ms', latency_ms, obj.AlertThreshold.latency_ms);
            end
            if error_rate > obj.AlertThreshold.error_rate
                alerts{end+1} = sprintf('HIGH_ERROR_RATE: %.2f%% > threshold %.2f%%', error_rate*100, obj.AlertThreshold.error_rate*100);
            end
            
            newRow = table(datetime('now'), mse, latency_ms, error_rate, ...
                'VariableNames', {'timestamp', 'mse', 'latency_ms', 'error_rate'});
            obj.MetricsHistory = [obj.MetricsHistory; newRow];
            
            if ~isempty(alerts)
                for i = 1:length(alerts)
                    logger.warning('[ALERT] %s', alerts{i});
                end
            end
        end
        
        function fig = plotHistory(obj)
            if height(obj.MetricsHistory) < 2
                fig = [];
                return;
            end
            fig = figure('Name', 'Monitoring History', 'NumberTitle', 'off');
            subplot(3, 1, 1);
            plot(obj.MetricsHistory.timestamp, obj.MetricsHistory.mse, 'b.-');
            yline(obj.AlertThreshold.mse, 'r--');
            title('MSE over Time'); grid on;
            
            subplot(3, 1, 2);
            plot(obj.MetricsHistory.timestamp, obj.MetricsHistory.latency_ms, 'g.-');
            yline(obj.AlertThreshold.latency_ms, 'r--');
            title('Latency (ms)'); grid on;
            
            subplot(3, 1, 3);
            plot(obj.MetricsHistory.timestamp, obj.MetricsHistory.error_rate * 100, 'm.-');
            yline(obj.AlertThreshold.error_rate * 100, 'r--');
            title('Error Rate (%)'); grid on;
        end
    end
end
