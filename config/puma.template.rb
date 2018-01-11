# Load rackup file
rackup 'config/config.ru'

# Number of cpu cores, does not work on windows
workers 4

# Tweak for better concurrency (recommended is 6 per number of workers/cores)
threads 6,24

# Run app in production
environment "production"

# Preload app
preload_app!
