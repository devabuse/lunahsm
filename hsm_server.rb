require "bunny"
require "json"
require "pkcs11"
require "yaml"

require_relative "src/authentication.rb"
require_relative "src/hsm_method.rb"
require_relative "src/generate_session_key.rb"
require_relative "src/verify_message.rb"
require_relative "src/sign_message.rb"
require_relative "src/luna.rb"

include PKCS11

config = YAML.load_file("config/config.yml")
connection = Bunny.new(config['rabbitmq'])
connection.start

channel = connection.create_channel
authentication = Authentication.new(config)
authentication.login()

class HsmServer
    def initialize(channel, authentication)
        @channel = channel
        @authentication = authentication
    end

    def start(queue_name)
        @queue = @channel.queue(queue_name, :durable => true)
        @exchange = @channel.default_exchange

        @queue.subscribe(:block => true) do |delivery_info, properties, params|
            begin
                p 'Received request from HSM client: ' + properties.correlation_id
                params = JSON.parse(params)

                if params[0].nil?
                    raise 'Please provide method'
                end

                instance = Luna.new(@authentication, params).getInstance()
                reply = instance.execute()
            rescue Exception => e
                reply = {:error => e.message}
            end

            @exchange.publish(reply.to_json, :persistent => true, :routing_key => properties.reply_to, :correlation_id => properties.correlation_id)
        end
    end
end

begin
    server = HsmServer.new(channel, authentication)
    p 'Awaiting requests to HSM'
    server.start("rpc_queue")
rescue Interrupt => _
    p 'Logout HSM'
    authentication.logout()
    p 'Close channel'
    channel.close
    p 'Close connection'
    connection.close
end
