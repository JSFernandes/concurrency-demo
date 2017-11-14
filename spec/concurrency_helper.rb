def make_concurrent_calls(count: 2)
  ActiveRecord::Base.connection.disconnect!
  Array.new(count) do |i|
    Process.fork do
      $stderr.reopen(File.new(File::NULL, "w"))
      $stdout.reopen(File.new(File::NULL, "w"))
      ActiveRecord::Base.establish_connection
      yield i
    end
  end
  ActiveRecord::Base.establish_connection
end

def add_breakpoint(breakpoints, object, breakpoint_name)
  flow, method_name = breakpoint_name.to_s.split(/_/, 2).map(&:to_sym)
  original_method = object.method(method_name)
  if flow == :before
    allow(object).to receive(method_name) do |*args|
      breakpoints << breakpoint_name
      original_method.call(*args)
    end
  elsif flow == :after
    allow(object).to receive(method_name) do |*args|
      value = original_method.call(*args)
      breakpoints << breakpoint_name
      value
    end
  end
end
