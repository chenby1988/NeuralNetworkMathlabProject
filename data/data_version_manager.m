classdef data_version_manager < handle
    % DATA_VERSION_MANAGER Tracks data lineage and versioning
    
    properties (Access = private)
        versionDir char
    end
    
    methods
        function obj = data_version_manager()
            obj.versionDir = 'artifacts/data_versions';
            if ~exist(obj.versionDir, 'dir')
                mkdir(obj.versionDir);
            end
        end
        
        function versionId = saveVersion(obj, X, Y, metadata)
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            hash = obj.computeHash(X, Y);
            versionId = sprintf('%s_%s', timestamp, hash);
            filePath = fullfile(obj.versionDir, sprintf('data_%s.mat', versionId));
            
            versionMeta = metadata;
            versionMeta.version_id = versionId;
            versionMeta.created_at = timestamp;
            versionMeta.hash = hash;
            versionMeta.sample_count = size(X, 1);
            
            save(filePath, 'X', 'Y', 'versionMeta');
            Logger.getInstance().info('Data version saved: %s (%d samples)', versionId, size(X, 1));
        end
        
        function [X, Y, meta] = loadVersion(obj, versionId)
            filePath = fullfile(obj.versionDir, sprintf('data_%s.mat', versionId));
            if ~exist(filePath, 'file')
                error('DataVersion:NotFound', 'Version %s not found', versionId);
            end
            S = load(filePath);
            X = S.X;
            Y = S.Y;
            meta = S.versionMeta;
            Logger.getInstance().info('Data version loaded: %s', versionId);
        end
        
        function versions = listVersions(obj)
            files = dir(fullfile(obj.versionDir, 'data_*.mat'));
            versions = struct('id', {}, 'created', {}, 'samples', {});
            for i = 1:length(files)
                name = files(i).name;
                id = extractBetween(name, 6, strlength(name)-4);
                versions(i).id = id;
                info = load(fullfile(obj.versionDir, name), 'versionMeta');
                versions(i).created = info.versionMeta.created_at;
                versions(i).samples = info.versionMeta.sample_count;
            end
        end
        
        function hash = computeHash(~, X, Y)
            hash = sprintf('%08X', mod(sum(X(:)) * 1e6 + sum(Y(:)) * 1e3, 2^32-1));
        end
    end
end
