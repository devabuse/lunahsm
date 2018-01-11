class Luna
    attr_accessor :auth, :params

    def initialize(auth, params)
        @auth = auth
        @params = params
        @method = params[0]

        if @method.nil?
            raise 'Please provide method'
        end
    end

    def getInstance()
        instance = nil;

        case @method
        when 'generate_session_key'
            instance = GenerateSessionKey.new(self)
        when 'sign_message'
            if @params[1].nil? || @params[2].nil?
                raise 'Please provide session_key and message'
            end

            session_key = @params[1]
            message = @params[2]

            instance = SignMessage.new(self, session_key, message)
        when 'verify_message'
            if @params[1].nil?
                raise 'Please provide message'
            end

            session_key = @params[1]
            mac = @params[2]
            masterkey_version = @params[3]
            message = @params[4]

            instance = VerifyMessage.new(self, session_key, mac, masterkey_version, message)
        end

        instance
    end

    def self.call_instance(config, params)
        include PKCS11

        authentication = Authentication.new(config)

        begin
            instance = Bancontact.new(authentication, ARGV).getInstance()
            puts instance.execute().to_json
            authentication.session.logout()
        rescue Interrupt => _
            authentication.session.logout()
        end
    end
end
