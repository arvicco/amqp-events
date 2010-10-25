shared_examples_for 'evented class' do
  specify { should respond_to :instance_events }
  its(:instance_events) { should be_an Array }

end

shared_examples_for 'evented object' do
  specify { should respond_to :events }
  its(:events) { should be_a Hash }

end

shared_examples_for 'object with pre-defined Events' do
  its(:events) { should_not be empty }

end