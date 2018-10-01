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

        if @method == 'generate_session_key'
            instance = GenerateSessionKey.new(self)
        elsif @method == 'sign_message'
            if @params[1].nil?
                raise 'Please provide the session_key'
            elsif @params[2].nil?
                raise 'Please provide the message '
            end

            session_key = @params[1]
            message = @params[2]

            instance = SignMessage.new(self, session_key, message)
        elsif @method == 'verify_message'
            if @params[1].nil?
                raise 'Please provide the session_key'
            elsif @params[2].nil?
                raise 'Please provide the expected mac'
            elsif @params[3].nil?
                raise 'Please provide the masterkey version'
            elsif @params[4].nil?
                raise 'Please provide the message'
            end

            session_key = @params[1]
            mac = @params[2]
            masterkey_version = @params[3]
            message = @params[4]

            instance = VerifyMessage.new(self, session_key, mac, masterkey_version, message)
        end

        instance
    end
end
