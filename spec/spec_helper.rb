require 'amqp-events'
require 'pathname'

require 'bundler'
Bundler.setup
Bundler.require :test

BASE_PATH = Pathname.new(__FILE__).dirname + '..'

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

module AmqpEventsTest

end # module AmqpEventsTest