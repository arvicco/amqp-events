require 'version'

module AMQP
  module Events
    require "bundler/setup"
#  Bundler.require :group

    # Requires ruby source file(s). Accepts either single filename/glob or Array of filenames/globs.
    # Accepts following options:
    # :*file*:: Lib(s) required relative to this file - defaults to __FILE__
    # :*dir*:: Required lib(s) located under this dir name - defaults to gem name
    #
    def self.require_libs(libs, opts={})
      file = Pathname.new(opts[:file] || __FILE__)
      [libs].flatten.each do |lib|
        name = file.dirname + (opts[:dir] || file.basename('.*')) + lib.gsub(/(?<!.rb)$/, '.rb')
        Pathname.glob(name.to_s).sort.each { |rb| require rb }
      end
    end

    if RUBY_PLATFORM =~ /mingw|mswin|windows/ #Windows!
      require 'uuid'
      UUID = UUID
    else
      require 'em/pure_ruby' unless defined? EventMachine::UuidGenerator
      UUID = EventMachine::UuidGenerator
    end

    class HandlerError < TypeError
    end

    class EventError < TypeError
    end
  end
end

# Require all ruby source files located under directory lib/amqp-events
# If you need files in specific order, you should specify it here before the glob
AMQP::Events.require_libs %W[events event **/*]
