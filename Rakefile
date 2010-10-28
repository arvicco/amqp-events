require 'pathname'
NAME = 'amqp-events'
BASE_PATH = Pathname.new(__FILE__).dirname
LIB_PATH =  BASE_PATH + 'lib'
PKG_PATH =  BASE_PATH + 'pkg'
DOC_PATH =  BASE_PATH + 'rdoc'

$LOAD_PATH.unshift LIB_PATH.to_s
require 'version'

CLASS_NAME = AMQP::Events
VERSION = CLASS_NAME::VERSION

require 'rake'

# Load rakefile tasks
Dir['tasks/*.rake'].sort.each { |file| load file }

