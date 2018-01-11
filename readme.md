# HSM

I was able to work with an HSM for some time and had to write an interface with it using Ruby. There is an excellent PKCS11 wrapper available, but not many examples to work with. This code is therefore provided as is for future reference and to help people get started. In this repository I have a working CLI interface and an API using Sonatra and Puma. Both of these options can connect to an HSM directly but can also use RabbitMQ as a broker, when configuration is setup for it.

I would not work with these files directly, but instead fork it and work with it as a base for your own project.

## Requirements

The setup assumes a set up luna client capable of connecting to a slot. Check this is possible using lunacm.

- Install RVM:
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable

- Install Ruby 2.4.2
rvm install 2.4.2
rvm use 2.4.2

- (optional) RabbitMQ installed and enabled in the config.yml. The web API requires this.

In folder with Gemfile run:
- gem install bundler
- bundle install

## Configuration
Copy config/config.template.yml to config/config.yml and setup the variables below
Copy config/puma.template.yml to config/puma.yml and setup the variables below

cryptoki_location: File location to the cryptoki.dll(windows) or cryptoki.so (linux) EX:
partition_password: The partition password
slot: An integer indicating the HA slot to connect with
masterkey_one: Encrypted masterkey
masterkey_two: Encrypted masterkey
masterkey_in_use: masterkey_one (masterkey to use for session key and signing). In our application we needed to be able to switch to a different masterkey
use_direct_connection: true when not using rabbitmq, false when using rabbitmq
rabbitmq: RabbitMQ path to connect with default is: amqp://guest:guest@localhost:5672

## CLI interface
The CLI interface can run with or without support for RabbitMQ. The downside of not using RabbitMQ is that a new connection to the HSM gets created everytime, which adds considerably latency. The use of the CLI interface with RabbitMQ is the fastest. Using the CLI interface without RabbitMQ is not recommended.

### Generate a session key
ruby main.rb generate_session_key
php json_decode(passthru('ruby hsm_client.rb generate_session_key'))
=> {"session_key":"22acdd7a71b4403adc8a5235ecf2be74dfb6399299de7a7f"}

### Calculate a mac of a message
ruby main.rb sign_message encrypted_session_key message
php json_decode(passthru('ruby hsm_client.rb sign_message encrypted_session_key message'))
=> {"signed":"55490cdf93982752f4e043ac6a1a7f22"}

### Verify mac of message
ruby main.rb verify_message encrypted_session_key expected_mac message
php json_decode(passthru('ruby hsm_client.rb verify_message encrypted_session_key expected_mac message'))
=> {"is_verified":true}
=> {"is_verified":false}

## Error messages
All commands can return json with an error message
=> {"error":"message"}

## Web API
To start the web api run puma after creating a puma.rb file in config. The web API requires RabbitMQ as a message broker.

GET /generate_session_key
- No parameters needed
=> {"session_key":"22acdd7a71b4403adc8a5235ecf2be74dfb6399299de7a7f"}

POST /sign_message
- Requires a JSON object with an encrypted session key and a message to calculate a mac for.
{
	"session_key" : "58907aba0ac3dfc17017d1e97a2f89eaba5d46641359ee97",
	"message" : "test"
}
=> {"signed":"55490cdf93982752f4e043ac6a1a7f22"}

POST /verify_message
- Requires a JSON object with an encrypted session key, the mac you are expecting and the message
{
	"session_key" : "58907aba0ac3dfc17017d1e97a2f89eaba5d46641359ee97",
	"mac" : "test",
	"message" : "test"
	"masterkey_version" : "000100"
	"return_full_mac" : false
}
=> {"is_verified":true}
=> {"is_verified":false}

## Performance
We have hree methods of connecting with the HSM to provide a fallback, below is a list in order of the fastest method as tested on a single laptop under Windows.

1) CLI interface with RabbitMQ
2) CLI interface without RabbitMQ (on linux)
3) Web API with RabbitMQ
