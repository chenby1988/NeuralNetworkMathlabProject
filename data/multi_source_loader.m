classdef multi_source_loader < handle
    % MULTI_SOURCE_LOADER Load data from various sources
    %   Supports: generator, csv, excel, mat
    
    methods (Static)
        function [X, Y, metadata] = load(sourceType, sourcePath, varargin)
            logger = Logger.getInstance();
            audit = AuditLogger.getInstance();
            
            logger.info('Loading data from source: %s', sourceType);
            
            switch lower(sourceType)
                case 'generator'
                    [X, Y, metadata] = multi_source_loader.generateSynthetic(varargin{:});
                case 'csv'
                    [X, Y, metadata] = multi_source_loader.loadCSV(sourcePath, varargin{:});
                case 'excel'
                    [X, Y, metadata] = multi_source_loader.loadExcel(sourcePath, varargin{:});
                case 'mat'
                    [X, Y, metadata] = multi_source_loader.loadMAT(sourcePath, varargin{:});
                otherwise
                    error('DataSource:Unknown', 'Unknown source type: %s', sourceType);
            end
            
            metadata.source = sourceType;
            metadata.loadTime = datestr(now);
            metadata.recordCount = length(Y);
            
            audit.logDataAccess(sourceType, length(Y), 'LOAD');
            logger.info('Data loaded: %d records', length(Y));
        end
        
        function [X, Y, metadata] = generateSynthetic(options)
            if nargin < 1 || isempty(options)
                options = struct();
            end
            N = getFieldOrDefault(options, 'N', 1000);
            noise_level = getFieldOrDefault(options, 'noise_level', 0.1);
            func = getFieldOrDefault(options, 'func', 'sin');
            x_range = getFieldOrDefault(options, 'x_range', [0, 2*pi]);
            
            rng(getFieldOrDefault(options, 'seed', 42));
            X = linspace(x_range(1), x_range(2), N)';
            
            switch func
                case 'sin'
                    Y_clean = sin(X);
                case 'cos'
                    Y_clean = cos(X);
                case 'complex'
                    Y_clean = sin(X) + 0.5*cos(3*X);
                case 'square'
                    Y_clean = sin(X).^2;
                otherwise
                    Y_clean = sin(X);
            end
            
            Y = Y_clean + noise_level * randn(size(X));
            metadata.function = func;
            metadata.noise_level = noise_level;
        end
        
        function [X, Y, metadata] = loadCSV(filePath, varargin)
            if ~exist(filePath, 'file')
                error('DataSource:NotFound', 'CSV file not found: %s', filePath);
            end
            opts = detectImportOptions(filePath);
            T = readtable(filePath, opts);
            [X, Y, metadata] = multi_source_loader.tableToXY(T, varargin{:});
        end
        
        function [X, Y, metadata] = loadExcel(filePath, varargin)
            if ~exist(filePath, 'file')
                error('DataSource:NotFound', 'Excel file not found: %s', filePath);
            end
            T = readtable(filePath);
            [X, Y, metadata] = multi_source_loader.tableToXY(T, varargin{:});
        end
        
        function [X, Y, metadata] = loadMAT(filePath, varargin)
            if ~exist(filePath, 'file')
                error('DataSource:NotFound', 'MAT file not found: %s', filePath);
            end
            S = load(filePath);
            if isfield(S, 'X') && isfield(S, 'Y')
                X = S.X;
                Y = S.Y;
            elseif isfield(S, 'data')
                X = S.data(:, 1:end-1);
                Y = S.data(:, end);
            else
                fields = fieldnames(S);
                X = S.(fields{1});
                Y = S.(fields{2});
            end
            metadata.file = filePath;
        end
        
        function [X, Y, metadata] = tableToXY(T, xCols, yCol)
            if nargin < 3
                yCol = T.Properties.VariableNames{end};
            end
            if nargin < 2
                xCols = T.Properties.VariableNames(1:end-1);
            end
            Y = T.(yCol);
            X = T{:, xCols};
            metadata.columns = struct('x', xCols, 'y', yCol);
        end
    end
end

function val = getFieldOrDefault(S, field, default)
    if isfield(S, field)
        val = S.(field);
    else
        val = default;
    end
end
