classdef ConfigManager < handle
    % CONFIGMANAGER Centralized configuration management
    %   Loads JSON config and provides dot-notation access
    
    properties (Access = private)
        data struct
        sourcePath char
    end
    
    methods (Static)
        function cfg = load(path)
            persistent cachedCfg cachedPath
            if nargin < 1 || isempty(path)
                path = 'config/system_config.json';
            end
            if ~isempty(cachedCfg) && strcmp(cachedPath, path) && ~isempty(dir(path))
                mtime = dir(path).datenum;
                if isequal(cachedCfg.mtime, mtime)
                    cfg = cachedCfg;
                    return;
                end
            end
            fid = fopen(path, 'r');
            if fid == -1
                error('ConfigManager:FileNotFound', 'Config file not found: %s', path);
            end
            raw = fread(fid, inf, '*char');
            fclose(fid);
            cfg = jsondecode(raw');
            d = dir(path);
            cfg.mtime = d.datenum;
            cachedCfg = cfg;
            cachedPath = path;
        end
        
        function val = get(cfg, keyPath, defaultVal)
            % Get nested value by dot-separated path, e.g. 'model.hidden_layers'
            if nargin < 3
                defaultVal = [];
            end
            parts = strsplit(keyPath, '.');
            val = cfg;
            for i = 1:length(parts)
                field = parts{i};
                if isstruct(val) && isfield(val, field)
                    val = val.(field);
                else
                    val = defaultVal;
                    return;
                end
            end
        end
        
        function cfg = merge(base, override)
            % Deep merge two config structs
            cfg = ConfigManager.deepMerge(base, override);
        end
    end
    
    methods (Static, Access = private)
        function out = deepMerge(a, b)
            out = a;
            if ~isstruct(b)
                out = b;
                return;
            end
            fields = fieldnames(b);
            for i = 1:length(fields)
                f = fields{i};
                if isfield(a, f) && isstruct(a.(f)) && isstruct(b.(f))
                    out.(f) = ConfigManager.deepMerge(a.(f), b.(f));
                else
                    out.(f) = b.(f);
                end
            end
        end
    end
end
