class Authentication
    TRANSPORTKEY_LABEL = 'KeyTransportKey'

    attr_accessor :pkcs11, :slot, :session, :masterkey

    def initialize(config)
        @config = config
        @pkcs11 = PKCS11.open(config['cryptoki_location'], :flags => CKF_OS_LOCKING_OK)
        @session = pkcs11.active_slots[config['slot']].open
        @masterkey = config[@config['masterkey_in_use']]
    end

    def login()
        @session.login(:USER, @config['partition_password'])
    end

    def logout()
        @session.logout()
    end

    def get_transport_key()
        @session.find_objects(:LABEL => TRANSPORTKEY_LABEL)[0]
    end

    def get_master_key(version = nil)
        if version.nil?
            masterkey_label =  @config['masterkey_in_use']
            masterkey = session.find_objects(:LABEL => masterkey_label)[0]
        else
            if version == 01
                version = 'one'
            elsif version == 02
                version = 'two'
            end

            masterkey_label =  @config['masterkey_' + version]

            if masterkey_label == '' || masterkey_label.nil?
                raise 'Unknown masterkey'
            end

            masterkey = session.find_objects(:LABEL => masterkey_label)[0]
        end

        if masterkey.nil?
            masterkey = @session.unwrap_key(:AES_ECB, get_transport_key(), Array(@masterkey).pack('H*'), :CLASS => CKO_SECRET_KEY, :KEY_TYPE => CKK_AES, :VALUE_LEN => 16, :EXTRACTABLE => true, :ENCRYPT => true, :DECRYPT => true, :SIGN => true, :VERIFY => true, :WRAP => true, :UNWRAP => true, :TOKEN => true, :LABEL => masterkey_label)
        end

        if masterkey.nil?
            raise 'Masterkey not found'
        end

        masterkey
    end

    def get_decrypted_master_key()
        session.decrypt(:AES_ECB, get_transport_key(), Array(@masterkey).pack('H*'))
    end
end
