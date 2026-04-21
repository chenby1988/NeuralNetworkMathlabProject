classdef AuditLogger < handle
    % AUDITLOGGER Security audit trail for compliance
    %   Records who did what, when, with what result
    
    properties (Access = private)
        auditFile char
        fid double
        enabled logical
    end
    
    methods (Static)
        function obj = getInstance()
            persistent instance
            if isempty(instance) || ~isvalid(instance)
                instance = AuditLogger();
            end
            obj = instance;
        end
    end
    
    methods (Access = private)
        function obj = AuditLogger()
            try
                cfg = ConfigManager.load();
                obj.enabled = ConfigManager.get(cfg, 'security.audit_enabled', true);
            catch
                obj.enabled = true;
            end
            auditDir = 'logs';
            if ~exist(auditDir, 'dir')
                mkdir(auditDir);
            end
            timestamp = datestr(now, 'yyyymmdd');
            obj.auditFile = fullfile(auditDir, sprintf('audit_%s.log', timestamp));
            obj.fid = fopen(obj.auditFile, 'a');
        end
    end
    
    methods
        function delete(obj)
            if obj.fid > 0
                fclose(obj.fid);
            end
        end
        
        function log(obj, action, details, user)
            if ~obj.enabled
                return;
            end
            if nargin < 4 || isempty(user)
                user = getenv('USERNAME');
                if isempty(user)
                    user = 'unknown';
                end
            end
            timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
            sessionId = sprintf('%08X', randi(intmax('uint32')));
            if isstruct(details)
                detailsStr = jsonencode(details);
            elseif ischar(details) || isstring(details)
                detailsStr = char(details);
            else
                detailsStr = mat2str(details);
            end
            line = sprintf('[%s] [SESSION:%s] [USER:%s] [ACTION:%s] %s', ...
                timestamp, sessionId, user, upper(action), detailsStr);
            fprintf(obj.fid, '%s\n', line);
            % fflush(obj.fid);
        end
        
        function logModelTrain(obj, modelId, params, metrics)
            obj.log('MODEL_TRAIN', struct('model_id', modelId, 'params', params, 'metrics', metrics));
        end
        
        function logDataAccess(obj, source, records, operation)
            obj.log('DATA_ACCESS', struct('source', source, 'records', records, 'op', operation));
        end
        
        function logConfigChange(obj, key, oldVal, newVal)
            obj.log('CONFIG_CHANGE', struct('key', key, 'old', oldVal, 'new', newVal));
        end
        
        function logExport(obj, modelId, format, destination)
            obj.log('MODEL_EXPORT', struct('model_id', modelId, 'format', format, 'dest', destination));
        end
    end
end
