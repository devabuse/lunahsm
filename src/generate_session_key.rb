class GenerateSessionKey < HsmMethod
    def execute
        master_key = @@luna.auth.get_master_key()

        # Use HSM to generate AES key
        session_key = @@luna.auth.session.generate_key(:AES_KEY_GEN, :CLASS => CKO_SECRET_KEY, :ENCRYPT => true, :SIGN => true, :EXTRACTABLE => true, :WRAP => true, :UNWRAP => true, :DECRYPT => true, :TOKEN => false, :VALUE_LEN => 16)

        # Wrap the session_key
        wrapped_key = @@luna.auth.session.wrap_key({@@aes_kw => ''}, master_key, session_key)

        {
            :session_key => wrapped_key.unpack('H*')[0]
        }
    end
end
