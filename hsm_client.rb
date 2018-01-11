require "bunny"
require "thread"
require 'securerandom'
require 'json'
require 'yaml'

class HsmClient
    attr_reader :reply_queue
    attr_accessor :response, :call_id
    attr_reader :lock, :condition

    def initialize(channel, server_queue)
        @channel = channel
        @exchange = channel.default_exchange

        @server_queue = server_queue
        @reply_queue = channel.queue("", :durable => true, :exclusive => true)

        @lock = Mutex.new
        @condition = ConditionVariable.new

        @reply_queue.subscribe do |delivery_info, properties, payload|
            if properties[:correlation_id] == self.call_id
                self.response = payload
                self.lock.synchronize{self.condition.signal}
            end
        end
    end

    def call(n, params)
        self.call_id = SecureRandom.uuid

        @exchange.publish(params.to_json, :routing_key => @server_queue, :correlation_id => call_id, :reply_to => @reply_queue.name, :persistent => true)

        lock.synchronize{condition.wait(lock)}
        response
    end

    def self.init(print_output, params)
        config = YAML.load_file("config/config.yml")
        connection = Bunny.new(config['rabbitmq'])
        connection.start

        channel = connection.create_channel

        client   = HsmClient.new(channel, "rpc_queue")
        response = client.call(30, params)

        channel.close
        connection.close

        if print_output
            puts "#{response}"
        end

        response
    end
end
