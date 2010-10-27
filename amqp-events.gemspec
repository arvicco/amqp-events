# Gemspecs should not be generated, but edited directly.
# Refer to: http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |gem|
  gem.name        = "amqp-events"
  gem.version     = File.open('VERSION').read.strip
  gem.summary     = "Distributed Events/RPC system using AMQP as a transport."
  gem.description = "Distributed Events/RPC system using AMQP as a transport (pre-alpha)"
  gem.authors     = ["arvicco"]
  gem.email       = "arvitallian@gmail.com"
  gem.homepage    = "http://github.com/arvicco/amqp-events"
  gem.platform    = Gem::Platform::RUBY
  gem.date        = Time.now.strftime "%Y-%m-%d"

  # Files setup
  versioned         = `git ls-files -z`.split("\0")
  gem.files         = Dir['{bin,lib,man,spec,features,tasks}/**/*', 'Rakefile', 'README*', 'LICENSE*',
                      'VERSION*', 'CHANGELOG*', 'HISTORY*', 'ROADMAP*', '.gitignore'] & versioned
  gem.executables   = (Dir['bin/**/*'] & versioned).map{|file|File.basename(file)}
  gem.test_files    = Dir['spec/**/*'] & versioned
  gem.require_paths = ["lib"]

  # RDoc setup
  gem.has_rdoc = true
  gem.rdoc_options.concat %W{--charset UTF-8 --main README.rdoc --title amqp-events}
  gem.extra_rdoc_files = ["LICENSE", "HISTORY", "README.rdoc"]
    
  # Dependencies
  gem.add_development_dependency("rspec", ['~>2.0.0'])
  gem.add_development_dependency("cucumber", [">= 0"])
  gem.add_dependency("amqp", ["~> 0.6.6"])
  gem.add_dependency("bundler", [">= 1.2.9"])

  # gem.rubyforge_project = ""
  # gem.rubygems_version  = `gem -v` # - Seems to conflict with Bundler
  # gem.required_rubygems_version = ">= 1.3.6"
end