classdef access_control < handle
    % ACCESS_CONTROL Role-based access control (RBAC)
    
    properties (Access = private)
        Users struct
        Roles struct
    end
    
    methods (Static)
        function obj = getInstance()
            persistent instance
            if isempty(instance) || ~isvalid(instance)
                instance = access_control();
            end
            obj = instance;
        end
    end
    
    methods (Access = private)
        function obj = access_control()
            obj.Roles.admin = {'train', 'predict', 'export', 'config', 'audit', 'user_manage'};
            obj.Roles.engineer = {'train', 'predict', 'export', 'config'};
            obj.Roles.analyst = {'predict', 'export'};
            obj.Roles.viewer = {'predict'};
            
            obj.Users.admin.role = 'admin';
            obj.Users.admin.password = obj.hash('admin123');
        end
        
        function h = hash(~, str)
            h = sprintf('%08X', string2hash(str));
        end
    end
    
    methods
        function ok = authenticate(obj, username, password)
            if ~isfield(obj.Users, username)
                ok = false;
                Logger.getInstance().warning('Auth failed: unknown user %s', username);
                return;
            end
            expected = obj.Users.(username).password;
            ok = strcmp(expected, obj.hash(password));
            if ok
                Logger.getInstance().info('User %s authenticated', username);
            else
                Logger.getInstance().warning('Auth failed for %s: wrong password', username);
            end
        end
        
        function ok = checkPermission(obj, username, action)
            if ~isfield(obj.Users, username)
                ok = false;
                return;
            end
            role = obj.Users.(username).role;
            permissions = obj.Roles.(role);
            ok = ismember(action, permissions);
            if ~ok
                Logger.getInstance().warning('Permission denied: %s cannot %s', username, action);
            end
        end
        
        function addUser(obj, username, password, role)
            if ~isfield(obj.Roles, role)
                error('AccessControl:InvalidRole', 'Role %s does not exist', role);
            end
            obj.Users.(username).role = role;
            obj.Users.(username).password = obj.hash(password);
            Logger.getInstance().info('User %s added with role %s', username, role);
        end
    end
end

function h = string2hash(str)
    h = 5381;
    for i = 1:length(str)
        h = bitshift(h, 5) + h + double(str(i));
    end
    h = mod(h, 2^31-1);
end
