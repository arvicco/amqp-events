# For more information on bundler, please visit http://gembundler.com
## Dependencies in this Gemfile are managed through the gemspec. Add/remove
## depenencies there, rather than editing this file
#
#require 'pathname'
#NAME = 'amqp-events'
#BASE_PATH = Pathname.new(__FILE__).dirname
#GEMSPEC_PATH = BASE_PATH + "#{NAME}.gemspec"
#
## Setup gemspec dependencies
#gemspec = eval(GEMSPEC_PATH.read)
#gemspec.dependencies.each do |dep|
#  group = dep.type == :development ? :development : :default
#  gem dep.name, dep.requirement, :group => group
#end
#gem(gemspec.name, gemspec.version, :path => BASE_PATH)

source :gemcutter
gem 'amqp', '~>0.6.6'

group :cucumber do
  gem 'cucumber'
  gem 'rspec', '~>1.3.0', require: ['spec/expectations', 'spec/stubs/cucumber']
  # add more here...
end

group :test do # Group for testing code on Windows (win, win_gui)
  gem 'rspec', '~>1.3.0', require: ['spec', 'spec/autorun']
  gem 'amqp-spec', '>=0.1.8', git: 'git://github.com/arvicco/amqp-spec.git', require: 'amqp-spec/rspec'
end

