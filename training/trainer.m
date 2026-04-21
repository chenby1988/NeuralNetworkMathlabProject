classdef trainer < handle
    % TRAINER Advanced training engine with checkpointing, early stopping, LR scheduling
    
    properties
        Config struct
        LrScheduler lr_scheduler
        CheckpointDir char
        BestNet
        BestValLoss double
        History struct
    end
    
    methods
        function obj = trainer(config)
            if nargin < 1
                config = ConfigManager.load();
            end
            obj.Config = config;
            trainCfg = config.model.training;
            obj.LrScheduler = lr_scheduler(trainCfg.learning_rate, 'step', ...
                'decay_rate', trainCfg.lr_decay, ...
                'decay_epochs', trainCfg.lr_decay_epochs);
            obj.CheckpointDir = 'artifacts/checkpoints';
            if ~exist(obj.CheckpointDir, 'dir')
                mkdir(obj.CheckpointDir);
            end
            obj.BestValLoss = inf;
            obj.History = struct('train_loss', [], 'val_loss', [], 'lr', [], 'epoch', []);
        end
        
        function [net, trainInfo] = train(obj, net, X_train, Y_train, X_val, Y_val)
            logger = Logger.getInstance();
            cfg = obj.Config.model.training;
            
            logger.info('========== TRAINING START ==========');
            logger.info('Max epochs: %d, Algorithm: %s', cfg.max_epochs, cfg.algorithm);
            
            % Check for checkpoint to resume
            [net, startEpoch, obj.History] = obj.loadCheckpoint(net);
            
            % Setup early stopping
            earlyStop = cfg.early_stop;
            patienceCounter = 0;
            
            % Training loop with manual epoch control for advanced features
            net.trainParam.epochs = 1; % We'll control epochs manually
            net.trainParam.showWindow = false;
            
            tic;
            for epoch = startEpoch:cfg.max_epochs
                % Update learning rate
                currentLr = obj.LrScheduler.step(epoch);
                net.trainParam.lr = currentLr;
                
                % Train one epoch
                net = train(net, X_train', Y_train');
                drawnow limitrate;  % Allow Ctrl+C to be processed
                
                % Evaluate
                Y_train_pred = net(X_train')';
                trainLoss = mean((Y_train - Y_train_pred).^2);
                
                Y_val_pred = net(X_val')';
                valLoss = mean((Y_val - Y_val_pred).^2);
                
                % Record history
                obj.History.train_loss(end+1) = trainLoss;
                obj.History.val_loss(end+1) = valLoss;
                obj.History.lr(end+1) = currentLr;
                obj.History.epoch(end+1) = epoch;
                
                % Checkpointing
                if cfg.checkpoint.enabled && mod(epoch, cfg.checkpoint.interval_epochs) == 0
                    obj.saveCheckpoint(net, epoch);
                end
                
                % Track best model
                if valLoss < obj.BestValLoss - earlyStop.min_delta
                    obj.BestValLoss = valLoss;
                    obj.BestNet = net;
                    patienceCounter = 0;
                else
                    patienceCounter = patienceCounter + 1;
                end
                
                % Early stopping
                if earlyStop.enabled && patienceCounter >= earlyStop.patience
                    logger.info('Early stopping triggered at epoch %d (patience=%d)', epoch, earlyStop.patience);
                    break;
                end
                
                % Log progress
                if mod(epoch, 10) == 0 || epoch == 1
                    logger.info('Epoch %4d | Train Loss: %.6f | Val Loss: %.6f | LR: %.6f', ...
                        epoch, trainLoss, valLoss, currentLr);
                end
                
                % Goal reached
                if trainLoss < cfg.goal
                    logger.info('Goal reached at epoch %d', epoch);
                    break;
                end
            end
            
            elapsed = toc;
            logger.info('========== TRAINING END (%.2fs, %d epochs) ==========', elapsed, epoch);
            
            % Return best model if available
            if ~isempty(obj.BestNet)
                net = obj.BestNet;
                logger.info('Restored best model (val_loss=%.6f)', obj.BestValLoss);
            end
            
            trainInfo = struct();
            trainInfo.epochs = epoch;
            trainInfo.final_train_loss = obj.History.train_loss(end);
            trainInfo.final_val_loss = obj.History.val_loss(end);
            trainInfo.best_val_loss = obj.BestValLoss;
            trainInfo.duration = elapsed;
            trainInfo.history = obj.History;
        end
        
        function saveCheckpoint(obj, net, epoch)
            fileName = sprintf('checkpoint_epoch_%04d.mat', epoch);
            filePath = fullfile(obj.CheckpointDir, fileName);
            checkpoint = struct();
            checkpoint.net = net;
            checkpoint.epoch = epoch;
            checkpoint.history = obj.History;
            checkpoint.best_val_loss = obj.BestValLoss;
            checkpoint.timestamp = datestr(now);
            save(filePath, '-struct', 'checkpoint');
            Logger.getInstance().debug('Checkpoint saved: %s', fileName);
        end
        
        function [net, startEpoch, history] = loadCheckpoint(obj, net)
            files = dir(fullfile(obj.CheckpointDir, 'checkpoint_epoch_*.mat'));
            if isempty(files)
                startEpoch = 1;
                history = struct('train_loss', [], 'val_loss', [], 'lr', [], 'epoch', []);
                return;
            end
            % Find latest checkpoint
            epochs = zeros(length(files), 1);
            for i = 1:length(files)
                name = files(i).name;
                epochs(i) = sscanf(name, 'checkpoint_epoch_%d.mat');
            end
            [maxEpoch, idx] = max(epochs);
            filePath = fullfile(files(idx).folder, files(idx).name);
            S = load(filePath);
            net = S.net;
            startEpoch = S.epoch + 1;
            history = S.history;
            obj.BestValLoss = S.best_val_loss;
            Logger.getInstance().info('Resumed from checkpoint epoch %d', S.epoch);
        end
        
        function clearCheckpoints(obj)
            files = dir(fullfile(obj.CheckpointDir, 'checkpoint_epoch_*.mat'));
            for i = 1:length(files)
                delete(fullfile(files(i).folder, files(i).name));
            end
            Logger.getInstance().info('All checkpoints cleared');
        end
    end
end
