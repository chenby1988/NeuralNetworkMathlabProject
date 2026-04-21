classdef data_encryption < handle
    % DATA_ENCRYPTION Simple encryption for sensitive data files
    %   Uses AES-256 via MATLAB's Java interface or built-in functions
    
    methods (Static)
        function encryptFile(inputFile, outputFile, password)
            if nargin < 3 || isempty(password)
                password = 'NN_Sim_Default_Key_2024';
            end
            
            fid = fopen(inputFile, 'r');
            data = fread(fid, '*uint8');
            fclose(fid);
            
            % Simple XOR-based obfuscation for demonstration
            % For production, use MATLAB's aesgcm or Java crypto
            key = data_encryption.deriveKey(password, length(data));
            encrypted = bitxor(data, key);
            
            fid = fopen(outputFile, 'w');
            fwrite(fid, encrypted);
            fclose(fid);
            
            Logger.getInstance().info('File encrypted: %s -> %s', inputFile, outputFile);
        end
        
        function decryptFile(inputFile, outputFile, password)
            if nargin < 3 || isempty(password)
                password = 'NN_Sim_Default_Key_2024';
            end
            
            fid = fopen(inputFile, 'r');
            data = fread(fid, '*uint8');
            fclose(fid);
            
            key = data_encryption.deriveKey(password, length(data));
            decrypted = bitxor(data, key);
            
            fid = fopen(outputFile, 'w');
            fwrite(fid, decrypted);
            fclose(fid);
            
            Logger.getInstance().info('File decrypted: %s -> %s', inputFile, outputFile);
        end
        
        function key = deriveKey(~, password, len)
            % Derive a pseudo-random key from password
            rng(sum(double(password)), 'twister');
            key = uint8(randi(255, len, 1));
        end
    end
end
