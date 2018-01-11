require "sinatra"
require "yaml"
require "json"
require "pkcs11"

require_relative "hsm_client.rb"

class Api < Sinatra::Base
    # Paths
    get '/generate_session_key' do
        content_type :json
        cache_control :no_store, :must_revalidate
        expires(0)

        HsmClient.init(false, ['generate_session_key'])
    end

    post '/sign_message' do
        content_type :json
        cache_control :no_store, :must_revalidate
        expires(0)

        data = JSON(request.body.read)

        HsmClient.init(false, ['sign_message', data['session_key'], data['message']])
    end

    post '/verify_message' do
        content_type :json
        cache_control :no_store, :must_revalidate
        expires(0)

        data = JSON(request.body.read)
        HsmClient.init(false, ['verify_message', data['session_key'], data['mac'], data['message'], data['masterkey_version']])
    end
end
