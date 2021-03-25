require  "message_channel"

p uri  =  ARGV.shift
p Channel  =  MessageChannel.new( uri )

Signal.trap( :INT ) do
  exit
end

Channel.listen( "hello", "world" ) do |topic, items|
  p [:async, topic, items]
end

Thread.start do
  while  true
    topic, items  =  Channel.listen( "hello", "world", timeout: rand )
    p [:await, topic, items]
  end
end

Thread.start do
  while  true
    Channel.notify( "hello",  at: Time.now.to_s )
    sleep  1
    Channel.notify( "world",  at: Time.now.to_s )
    sleep  1
  end
end

sleep

