class SignMessage < HsmMethod
    def initialize(luna, session_key, message)
        @session_key = session_key
        @message = Array(message).pack('H*')

        super(bancontact)
    end

    def execute
        master_key = @@luna.auth.get_master_key()

        unwrapped_key = @@luna.auth.session.unwrap_key({@@aes_kw => ''}, master_key, Array(@session_key).pack('H*'), :CLASS => CKO_SECRET_KEY, :KEY_TYPE => CKK_AES, :VALUE_LEN => 16, :ENCRYPT => true, :DECRYPT => true, :WRAP => true, :UNWRAP => true, :SIGN => true, :VERIFY => true, :TOKEN => false)

        {
            :signed => @@luna.auth.session.sign(:AES_CMAC, unwrapped_key, @message).unpack('H*')[0][0..16]
        }
    end
end
