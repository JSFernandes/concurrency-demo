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
