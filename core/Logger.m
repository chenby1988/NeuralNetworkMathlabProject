classdef Logger < handle
    % LOGGER Professional logging system for NN simulation
    %   Supports levels: DEBUG < INFO < WARNING < ERROR < CRITICAL
    %   Writes to both console and file
    
    properties (Access = private)
        logFile char
        level int32
        fid double
        isOpen logical = false
    end
    
    properties (Constant)
        LEVEL_DEBUG = 0
        LEVEL_INFO = 1
        LEVEL_WARNING = 2
        LEVEL_ERROR = 3
        LEVEL_CRITICAL = 4
        LEVEL_NAMES = {'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'}
    end
    
    methods (Static)
        function obj = getInstance(configPath)
            persistent instance
            if isempty(instance) || ~isvalid(instance)
                if nargin < 1 || isempty(configPath)
                    configPath = 'config/system_config.json';
                end
                instance = Logger(configPath);
            end
            obj = instance;
        end
    end
    
    methods (Access = private)
        function obj = Logger(configPath)
            obj.init(configPath);
        end
        
        function init(obj, configPath)
            cfg = ConfigManager.load(configPath);
            logDir = cfg.system.log_dir;
            if ~exist(logDir, 'dir')
                mkdir(logDir);
            end
            levelStr = cfg.system.log_level;
            obj.level = obj.parseLevel(levelStr);
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            obj.logFile = fullfile(logDir, sprintf('nn_sim_%s.log', timestamp));
            obj.fid = fopen(obj.logFile, 'a');
            if obj.fid == -1
                error('Logger:CannotOpen', 'Cannot open log file: %s', obj.logFile);
            end
            obj.isOpen = true;
            fprintf('Logger initialized. Level: %s, File: %s\n', levelStr, obj.logFile);
        end
        
        function lv = parseLevel(~, str)
            switch upper(str)
                case 'DEBUG', lv = Logger.LEVEL_DEBUG;
                case 'INFO', lv = Logger.LEVEL_INFO;
                case 'WARNING', lv = Logger.LEVEL_WARNING;
                case 'ERROR', lv = Logger.LEVEL_ERROR;
                case 'CRITICAL', lv = Logger.LEVEL_CRITICAL;
                otherwise, lv = Logger.LEVEL_INFO;
            end
        end
        
        function write(obj, level, msg, varargin)
            if level < obj.level
                return;
            end
            timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
            levelName = Logger.LEVEL_NAMES{level + 1};
            if nargin > 3
                msg = sprintf(msg, varargin{:});
            end
            line = sprintf('[%s] [%s] %s', timestamp, levelName, msg);
            fprintf('%s\n', line);
            if obj.isOpen
                fprintf(obj.fid, '%s\n', line);
                % fflush(obj.fid);
            end
        end
    end
    
    methods
        function delete(obj)
            if obj.isOpen && obj.fid > 0
                obj.info('Logger shutting down.');
                fclose(obj.fid);
                obj.isOpen = false;
            end
        end
        
        function debug(obj, msg, varargin)
            obj.write(Logger.LEVEL_DEBUG, msg, varargin{:});
        end
        
        function info(obj, msg, varargin)
            obj.write(Logger.LEVEL_INFO, msg, varargin{:});
        end
        
        function warning(obj, msg, varargin)
            obj.write(Logger.LEVEL_WARNING, msg, varargin{:});
        end
        
        function error(obj, msg, varargin)
            obj.write(Logger.LEVEL_ERROR, msg, varargin{:});
        end
        
        function critical(obj, msg, varargin)
            obj.write(Logger.LEVEL_CRITICAL, msg, varargin{:});
        end
    end
end
