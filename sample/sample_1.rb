require  "message_channel"

p uri  =  ARGV.shift
p Channel  =  MessageChannel.new( uri )

Signal.trap( :INT ) do
  exit
end

Channel.listen( "hello" ) do |topic, items|
  p [topic, items]
end

while  true
  Channel.notify( "hello",  at: Time.now.to_s )
  sleep  1
end

