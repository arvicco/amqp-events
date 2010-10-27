def subscribers_to_be_called(num, event = subject)
  @counter = 0

  event.subscribers.should have(num).subscribers
  event.listeners.should have(num).listeners

  event.fire "data" # fire Event, sending "data" to subscribers
  @counter.should == num
end

def should_be_defined_event(object=subject, name)
  object.should respond_to name.to_sym
  object.should respond_to "#{name}=".to_sym
  object.events.should include name.to_sym
  object.class.instance_events.should include name.to_sym
  object.events.should_not include name.to_s
  object.class.instance_events.should_not include name.to_s
  object.send(name.to_sym).should be_kind_of AMQP::Events::Event
end

def define_subscribers
  def self.subscriber_method(*args)
    args.should == ["data"]
    @counter += 1
  end

  @subscriber_proc = proc do |*args|
    args.should == ["data"]
    @counter += 1
  end
end

shared_examples_for 'evented class' do
  specify { should respond_to :instance_events }
  specify { should respond_to :event }
  its(:instance_events) { should be_a Hash }

end

shared_examples_for 'evented object' do

  specify { should respond_to :event }
  specify { should respond_to :events }
  its(:events) { should be_a Hash }

  it 'it`s events property contains Events that know about their name and host' do
    subject.events.each do |name, event|
      event.should be_kind_of AMQP::Events::Event
      event.name.should == name
      event.host.should == subject
    end
  end

  context 'with proc/method/block @subscribers and at least Bar event defined' do
    before do
      define_subscribers
      subject.event :Bar unless subject.class.instance_events.include? :Bar
    end

    context 'creating new (class-wide) Events' do
      before { @events_size = subject.events.size }

      it 'should create events on instance, with Symbol as a name' do
  # object effectively defines new Event for all similar instances... Should it be allowed?
        res = subject.event :Grumple
        res.should == subject.Grumple # returns new Event
        should_be_defined_event :Grumple
        subject.events.size.should == @events_size + 1
      end

      it 'should create events on instance, with String as a name' do
  # object effectively defines new Event for all similar instances... Should it be allowed?
        res = subject.event 'Blurp'
        res.should == subject.Blurp # returns new Event
        should_be_defined_event :Blurp
        subject.events.size.should == @events_size + 1
      end

      it 'should not redefine already defined events' do
        res = subject.event :Bar
        res.should == subject.Bar # returns existing Event
        should_be_defined_event :Bar
        subject.events.size.should == @events_size

        res = subject.event 'Bar'
        res.should == subject.Bar # returns existing Event
        should_be_defined_event :Bar
        subject.events.size.should == @events_size
      end
    end

    context '#Bar and #Bar= accessor method for defined Event' do
      it 'should respond to #Bar and #Bar=' do
        should respond_to :Bar
        should respond_to :Bar=
      end

      specify 'calling Bar without args returns Bar event itself' do
        subject.Bar.should == subject.events[:Bar]
      end

      it 'allows assignment of pre-defined Event to self (+=/-=)' do
        events_size = subject.events.size
        subject.Bar = subject.Bar
        subject.Bar = subject.event(:Bar)
        subject.Bar = subject.events[:Bar]

        subject.class.instance_events.should include :Bar
        subject.events.size.should == events_size
      end

      it 'raises error if you try to assign anything else to Event' do
        events_size = subject.events.size
        other_event = AMQP::Events::Event.create(self, :Foo)
        same_name_event = AMQP::Events::Event.create(self, :Bar)
        other_object_event = AMQP::Events::Event.create(Object.new, :Bar)

        [1, 'event', :Baz, other_event, same_name_event, other_object_event, proc {}].each do |rvalue|
          expect { subject.Bar = rvalue }.to raise_error AMQP::Events::EventError, /Wrong assignment/
        end
        subject.class.instance_events.should include :Bar
        subject.events.size.should == events_size
      end

    end

    context "#subscribe to object's Event" do

      it "allows access to object's Events through its #events property" do
        subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
        subject.events[:Bar].subscribe(:bar2, method(:subscriber_method))
        subject.events[:Bar].subscribe(:bar3, @subscriber_proc)

        subscribers_to_be_called 3, subject.Bar
      end

      it "syntax-sugars object.Event#subscribe as object.subscribe(:Event)" do
        subject.subscribe(:Bar) { |*args| args.should == ["data"]; @counter += 1 }
        subject.subscribe(:Bar, :bar1, @subscriber_proc)
        subject.subscribe(:Bar, :bar2, @subscriber_proc)
        subject.subscribe(:Bar, :bar3, &@subscriber_proc)
        subject.subscribe :Bar, @subscriber_proc
        subject.subscribe :Bar, &@subscriber_proc
        subject.listen :Bar, @subscriber_proc
        subject.subscribe(:Bar, :bar4, method(:subscriber_method))
        subject.subscribe(:Bar, :bar5, method(:subscriber_method))
        res = subject.listen(:Bar, :bar6, method(:subscriber_method))

        res.should be_an AMQP::Events::Event
        res.name.should == :Bar
        subscribers_to_be_called 10, subject.Bar
      end
    end #subscribe

    context "#unsubscribe from object's Event" do
      before { define_subscribers }

      it "allows you to unsubscribe from Events by name" do
        subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
        subject.events[:Bar].subscribe(:bar2, method(:subscriber_method))
        subject.events[:Bar].subscribe(:bar3, @subscriber_proc)

        subject.events[:Bar].unsubscribe(:bar1)
        subject.events[:Bar].unsubscribe(:bar2)
        subject.events[:Bar].unsubscribe(:bar3)

        subscribers_to_be_called 0, subject.Bar
      end

      it "syntax-sugars object.Event#unsubscribe as object.unsubscribe(:Event)" do
        subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
        subject.events[:Bar].subscribe(:bar2, method(:subscriber_method))
        subject.events[:Bar].subscribe(:bar3, @subscriber_proc)

        subject.unsubscribe(:Bar, :bar1)
        subject.unsubscribe(:Bar, :bar2)
        subject.remove(:Bar, :bar3)

        subscribers_to_be_called 0, subject.Bar
      end

      it "raises error trying to unsubscribe undefined Event)" do
        expect { subject.unsubscribe(:Gurgle, :bar) }.
                to raise_error /Unable to unsubscribe, there is no event Gurgle/

        subscribers_to_be_called 0, subject.Bar
      end

      it "raises error trying to unsubscribe unknown subscriber)" do
        subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }

        expect { subject.unsubscribe(:Bar, @subscriber_proc) }.
                to raise_error /Unable to unsubscribe handler/

        subscribers_to_be_called 1, subject.Bar
      end
    end
  end #unsubscribe
end

shared_examples_for('event') do
  before do
    define_subscribers
    @subject = subject # subject += subscriber # Doesn't work, Ruby considers subject a local var here
  end

  specify { should respond_to :name }
  specify { should respond_to :host } # Event should know what object it is attached to
  its(:subscribers) { should be_a Hash }

  context "#subscribe to Event" do
    it 'allows anyone to add block subscribers/listeners (multiple syntax)' do
      subject.subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
      subject.listen(:bar2) { |*args| args.should == ["data"]; @counter += 1 }

      subscribers_to_be_called 2
    end

    it 'allows anyone to add method subscribers/listeners (multiple syntax)' do
      subject.subscribe(:bar1, method(:subscriber_method))
      subject.listen(:bar2, method(:subscriber_method))
      subject.listen(method(:subscriber_method))
      @subject += method(:subscriber_method)

      subscribers_to_be_called 4
    end

    it 'allows anyone to add proc subscribers/listeners (multiple syntax)' do
      subject.subscribe(:bar1, @subscriber_proc)
      subject.subscribe(:bar2, &@subscriber_proc)
      subject.subscribe @subscriber_proc
      subject.subscribe &@subscriber_proc
      subject.listen @subscriber_proc
      @subject += @subscriber_proc

      subscribers_to_be_called 6
    end

    it "allows you to mix subscriber types" do
      subject.subscribe { |*args| args.should == ["data"]; @counter += 1 }
      @subject += method :subscriber_method
      @subject += @subscriber_proc

      subscribers_to_be_called 3
    end

    it "raises exception if the given handler is not callable" do
      [:subscriber_symbol, 1, [1, 2, 3], {me: 2}].each do |args|
        expect { subject.subscribe(args) }.
                to raise_error /Handler .* does not respond to #call/
        expect { subject.subscribe(:good_name, args) }.
                to raise_error /Handler .* does not respond to #call/

        subscribers_to_be_called 0
      end
    end

    it "raises exception when adding handler with duplicate name" do
      subject.listen(:bar1) { |*args| args.should == ["data"]; @counter += 1 }

      expect { subject.listen(:bar1) { |*args| args.should == ["data"]; @counter += 1 } }.
              to raise_error /Handler name bar1 already in use/
      expect { subject.listen(:bar1, @subscriber_proc) }.
              to raise_error /Handler name bar1 already in use/

      subscribers_to_be_called 1
    end
  end #subscribe

  context "#unsubscribe from Event" do

    it "allows you to unsubscribe from Events by name" do
      subject.subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
      subject.subscribe(:bar2, method(:subscriber_method))
      subject.subscribe(:bar3, @subscriber_proc)

      subject.unsubscribe(:bar1)
      subject.remove(:bar2)
      @subject -= :bar3

      subscribers_to_be_called 0
    end

    it "raises exception if the name is unknown or wrong" do
      subject.subscribe(@subscriber_proc)

      expect { subject.unsubscribe(@subscriber_proc) }.
              to raise_error /Unable to unsubscribe handler/
      expect { subject.unsubscribe('I-dont-know') }.
              to raise_error /Unable to unsubscribe handler I-dont-know/

      subscribers_to_be_called 1
    end
  end #unsubscribe
end
