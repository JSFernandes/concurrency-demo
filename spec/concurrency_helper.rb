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

def make_forkbreak_process
  ForkBreak::Process.new do |breakpoints|
    $stderr.reopen(File.new(File::NULL, "w"))
    $stdout.reopen(File.new(File::NULL, "w"))
    ActiveRecord::Base.establish_connection
    yield breakpoints
  end
end

def run_forkbreak_processes(processes, breakpoints)
  ActiveRecord::Base.connection.disconnect!
  breakpoints.each do |brk|
    processes.each do |process|
      process.run_until(brk).wait
    end
  end

  processes.each do |process|
    process.finish.wait
  end
ensure
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
