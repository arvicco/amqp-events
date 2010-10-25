shared_examples_for 'evented class' do
  specify { should respond_to :instance_events }
  its(:instance_events) { should be_an Array }

end

shared_examples_for 'evented object' do
  specify { should respond_to :events }
  its(:events) { should be_a Hash }

  context "#subscribe to object's Event" do
    before do
        define_subscribers
        subject.event :Bar unless subject.class.instance_events.include? :Bar
      end

    it 'allows anyone to add block subscribers/listeners (multiple syntax)' do
      subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
      subject.Bar.subscribe(:bar2) { |*args| args.should == ["data"]; @counter += 1 }
      subject.Bar.listen(:bar3) { |*args| args.should == ["data"]; @counter += 1 }

      subscribers_to_be_called 3
    end

    it 'allows anyone to add method subscribers/listeners (multiple syntax)' do
      subject.events[:Bar].subscribe(:bar1, method(:subscriber_method))
      subject.Bar.subscribe(:bar2, method(:subscriber_method))
      subject.Bar.listen(:bar3, method(:subscriber_method))
      subject.Bar.listen(method(:subscriber_method))
      subject.Bar += method(:subscriber_method)

      subscribers_to_be_called 5
    end

    it 'allows anyone to add proc subscribers/listeners (multiple syntax)' do
      subject.events[:Bar].subscribe(:bar1, @subscriber_proc)
      subject.Bar.subscribe(:bar2, @subscriber_proc)
      subject.Bar.subscribe(:bar3, &@subscriber_proc)
      subject.Bar.subscribe @subscriber_proc
      subject.Bar.subscribe &@subscriber_proc
      subject.Bar.listen @subscriber_proc
      subject.Bar += @subscriber_proc

      subscribers_to_be_called 7
    end

    it "allows you to mix subscriber types for one Event" do
      subject.Bar.subscribe { |*args| args.should == ["data"]; @counter += 1 }
      subject.Bar += method :subscriber_method
      subject.Bar += @subscriber_proc

      subscribers_to_be_called 3
    end

    it "syntax-sugars object.Event#subscribe as object.subscribe(:Event)" do
      subject.subscribe(:Bar) { |*args| args.should == ["data"]; @counter += 1 }
      subject.subscribe(:Bar, :bar1, @subscriber_proc)
      subject.subscribe(:Bar, :bar2, @subscriber_proc)
      subject.subscribe(:Bar, :bar3, &@subscriber_proc)
      subject.subscribe :Bar,  @subscriber_proc
      subject.subscribe :Bar, &@subscriber_proc
      subject.listen :Bar, @subscriber_proc
      subject.subscribe(:Bar, :bar4, method(:subscriber_method))
      subject.subscribe(:Bar, :bar5, method(:subscriber_method))
      subject.listen(:Bar, :bar6, method(:subscriber_method))

      subscribers_to_be_called 10
    end

    it "raises exception if the given handler is not callable" do
      [:subscriber_symbol, 1, [1, 2, 3], {me: 2}].each do |args|
        expect { subject.Bar.subscribe(args) }.
                to raise_error /Handler .* does not respond to #call/
        expect { subject.Bar.subscribe(:good_name, args) }.
                to raise_error /Handler .* does not respond to #call/

        subscribers_to_be_called 0
      end
    end

    it "raises exception when adding handler with duplicate name" do
      subject.Bar.listen(:bar1) { |*args| args.should == ["data"]; @counter += 1 }

      expect { subject.Bar.listen(:bar1) { |*args| args.should == ["data"]; @counter += 1 } }.
              to raise_error /Handler name bar1 already in use/
      expect { subject.Bar.listen(:bar1, @subscriber_proc) }.
              to raise_error /Handler name bar1 already in use/

      subscribers_to_be_called 1
    end
  end #subscribe

  context "#unsubscribe from object's Event" do
    before { define_subscribers }

    it "allows you to unsubscribe from Events by name" do
      subject.Bar.subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
      subject.Bar.subscribe(:bar2, method(:subscriber_method))
      subject.Bar.subscribe(:bar3, @subscriber_proc)

      subject.Bar.unsubscribe(:bar1)
      subject.Bar.unsubscribe(:bar2)
      subject.Bar.unsubscribe(:bar3)

      subscribers_to_be_called 0
    end

    it "raises exception if the name is unknown or wrong" do
      subject.Bar.subscribe(@subscriber_proc)

      expect { subject.Bar.unsubscribe(@subscriber_proc) }.
              to raise_error /Unable to unsubscribe handler/
      expect { subject.Bar.unsubscribe('I-dont-know') }.
              to raise_error /Unable to unsubscribe handler I-dont-know/

      subscribers_to_be_called 1
    end
  end #unsubscribe
end

shared_examples_for 'object with pre-defined Events' do
  its(:events) { should_not be empty }

end