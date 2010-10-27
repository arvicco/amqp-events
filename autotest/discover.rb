Autotest.add_hook :initialize do |autotest|
  %w{.git .idea vendor public log misc temp tmp}.each {|exception| autotest.add_exception(exception)}
end
Autotest.add_discovery { "rspec2" }


