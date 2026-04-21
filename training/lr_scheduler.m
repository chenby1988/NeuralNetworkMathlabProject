classdef lr_scheduler < handle
    % LR_SCHEDULER Learning rate scheduling strategies
    
    properties
        initial_lr double
        current_lr double
        strategy char
        decay_rate double
        decay_epochs int32
        step_size int32
        warmup_epochs int32
        epoch int32
    end
    
    methods
        function obj = lr_scheduler(initial_lr, strategy, varargin)
            if nargin < 2 || isempty(strategy)
                strategy = 'step';
            end
            obj.initial_lr = initial_lr;
            obj.current_lr = initial_lr;
            obj.strategy = strategy;
            obj.epoch = 0;
            
            p = inputParser;
            addParameter(p, 'decay_rate', 0.95);
            addParameter(p, 'decay_epochs', 50);
            addParameter(p, 'step_size', 100);
            addParameter(p, 'warmup_epochs', 0);
            parse(p, varargin{:});
            
            obj.decay_rate = p.Results.decay_rate;
            obj.decay_epochs = p.Results.decay_epochs;
            obj.step_size = p.Results.step_size;
            obj.warmup_epochs = p.Results.warmup_epochs;
        end
        
        function lr = step(obj, epoch)
            obj.epoch = epoch;
            switch lower(obj.strategy)
                case 'fixed'
                    lr = obj.initial_lr;
                case 'step'
                    lr = obj.initial_lr * (obj.decay_rate ^ floor(epoch / obj.step_size));
                case 'exponential'
                    lr = obj.initial_lr * (obj.decay_rate ^ epoch);
                case 'cosine'
                    lr = obj.initial_lr * 0.5 * (1 + cos(pi * epoch / obj.decay_epochs));
                case 'warmup_cosine'
                    if epoch < obj.warmup_epochs
                        lr = obj.initial_lr * (epoch / obj.warmup_epochs);
                    else
                        progress = (epoch - obj.warmup_epochs) / (obj.decay_epochs - obj.warmup_epochs);
                        lr = obj.initial_lr * 0.5 * (1 + cos(pi * progress));
                    end
                otherwise
                    lr = obj.initial_lr;
            end
            obj.current_lr = lr;
        end
        
        function reset(obj)
            obj.current_lr = obj.initial_lr;
            obj.epoch = 0;
        end
    end
end
