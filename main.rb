require "yaml"

config = YAML.load_file(File.dirname(__FILE__) + "/config/config.yml")

if config['use_direct_connection']
    require "pkcs11"
    require "json"

    require_relative "src/authentication.rb"
    require_relative "src/hsm_method.rb"
    require_relative "src/generate_session_key.rb"
    require_relative "src/verify_message.rb"
    require_relative "src/sign_message.rb"
    require_relative "src/luna.rb"

    include PKCS11

    authentication = Authentication.new(config)
    authentication.login()

    begin
        instance = Luna.new(authentication, ARGV).getInstance()
        puts instance.execute().to_json
        authentication.logout()
    rescue Interrupt => _
        authentication.logout()
    end
else
    require_relative "hsm_client.rb"

    HsmClient.init(ARGV, config['rabbitmq'])
end
