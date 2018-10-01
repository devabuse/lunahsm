class Authentication
    TRANSPORTKEY_LABEL = 'KeyTransportKey'

    attr_accessor :session, :masterkey_cache

    def initialize(config)
        @config = config
        @session = PKCS11.open(config['cryptoki_location']).active_slots[config['slot']].open
        @masterkey_cache = Hash.new
    end

    def login()
        @session.login(:USER, @config['partition_password'])
        @masterkey_cache['masterkey_one'] = load_masterkey('masterkey_one', @config['masterkey_one'])
        @masterkey_cache['masterkey_two'] = load_masterkey('masterkey_two', @config['masterkey_two'])
    end

    def logout()
        @session.logout()
    end

    def get_transport_key()
        @session.find_objects(:LABEL => TRANSPORTKEY_LABEL)[0]
    end

    def get_master_key(version = nil)
        if version.nil?
            masterkey = masterkey_cache[@config['masterkey_in_use']]
        else
            masterkey = @masterkey_cache['masterkey_one']

            if version == '02'
                masterkey = @masterkey_cache['masterkey_two']
            end
        end

        if masterkey.nil?
            raise 'Masterkey not found'
        end

        masterkey
    end

    def load_masterkey(label, key)
        masterkey = session.find_objects(:LABEL => label)[0]

        if masterkey.nil?
            masterkey = @session.unwrap_key(:AES_ECB, get_transport_key(), Array(key).pack('H*'), :CLASS => CKO_SECRET_KEY, :KEY_TYPE => CKK_AES, :VALUE_LEN => 16, :EXTRACTABLE => true, :ENCRYPT => true, :DECRYPT => true, :SIGN => true, :VERIFY => true, :WRAP => true, :UNWRAP => true, :TOKEN => true, :LABEL => label)
        end

        masterkey
    end
end
