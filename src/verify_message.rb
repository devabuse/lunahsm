class VerifyMessage < HsmMethod
    def initialize(bancontact, session_key, expected_mac, masterkey_version, message)
        @session_key = session_key
        @message = Array(message).pack('H*')
        @masterkey_version = masterkey_version
        @expected_mac = expected_mac

        super(bancontact)
    end

    def execute
        master_key = @@luna.auth.get_master_key(@masterkey_version)

        unwrapped_key = @@luna.auth.session.unwrap_key({@@aes_kw => ''}, master_key, Array(@session_key).pack('H*'), :CLASS => CKO_SECRET_KEY, :KEY_TYPE => CKK_AES, :VALUE_LEN => 16, :ENCRYPT => true, :DECRYPT => true, :WRAP => true, :UNWRAP => true, :SIGN => true, :VERIFY => true, :TOKEN => false)
        mac = @@luna.auth.session.sign(:AES_CMAC, unwrapped_key, @message).unpack('H*')[0][0..16]

        {
            :is_verified => @expected_mac == mac
        }
    end
end
