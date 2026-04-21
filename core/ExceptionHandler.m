classdef ExceptionHandler < handle
    % EXCEPTIONHANDLER Unified error handling with recovery strategies
    
    methods (Static)
        function result = safeExecute(func, varargin)
            % Execute function with automatic error catching and logging
            logger = Logger.getInstance();
            try
                logger.debug('Executing: %s', func2str(func));
                if nargin > 1
                    result = func(varargin{:});
                else
                    result = func();
                end
            catch ME
                logger.error('Exception in %s: %s', func2str(func), ME.message);
                for k = 1:length(ME.stack)
                    logger.error('  at %s (line %d)', ME.stack(k).name, ME.stack(k).line);
                end
                result = [];
                rethrow(ME);
            end
        end
        
        function result = safeExecuteWithFallback(func, fallbackVal, varargin)
            % Execute with fallback value on error
            logger = Logger.getInstance();
            try
                if nargin > 2
                    result = func(varargin{:});
                else
                    result = func();
                end
            catch ME
                logger.warning('Fallback triggered for %s: %s. Using default.', ...
                    func2str(func), ME.message);
                result = fallbackVal;
            end
        end
        
        function validateNotEmpty(val, name)
            if isempty(val)
                error('ValidationError:Empty', '%s cannot be empty.', name);
            end
        end
        
        function validateRange(val, minVal, maxVal, name)
            if any(val < minVal) || any(val > maxVal)
                error('ValidationError:OutOfRange', ...
                    '%s must be in range [%.4f, %.4f].', name, minVal, maxVal);
            end
        end
        
        function validateDimensions(val, expectedRows, expectedCols, name)
            [r, c] = size(val);
            if r ~= expectedRows || c ~= expectedCols
                error('ValidationError:Dimensions', ...
                    '%s expected [%d, %d], got [%d, %d].', name, expectedRows, expectedCols, r, c);
            end
        end
    end
end
