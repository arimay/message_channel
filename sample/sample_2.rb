require  "message_channel"

p uri  =  ARGV.shift
p Channel  =  MessageChannel.new( uri )

Signal.trap( :INT ) do
  exit
end

Thread.start do
  while  true
    topic, items  =  Channel.listen( "hello", timeout: 0.5 )
    p [topic, items]
  end
end

while  true
  Channel.notify( "hello",  at: Time.now.to_s )
  sleep  rand
end

