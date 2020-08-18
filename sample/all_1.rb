require  "message_channel"

ObserverChannel  =  MessageChannel.new( "observer" )
DrubyChannel     =  MessageChannel.new( "druby" )
MqttChannel      =  MessageChannel.new( "mqtt" )
RedisChannel     =  MessageChannel.new( "redis" )
MongodbChannel   =  MessageChannel.new( "mongodb" )

Signal.trap( :INT ) do
  exit
end

mask1  =  "observer/*"
ObserverChannel.listen( mask1 ) do |topic, items|
  p [:observer, mask1, topic, items]
end

mask2  =  "druby___/*" 
DrubyChannel.listen( mask2 ) do |topic, items|
  p [:druby___, mask2, topic, items]
end

mask3  =  "mqtt____/+" 
MqttChannel.listen( mask3 ) do |topic, items|
  p [:mqtt____, mask3, topic, items]
end

mask4  =  "redis___/*"
RedisChannel.listen( mask4 ) do |topic, items|
  p [:redis___, mask4, topic, items]
end

mask5  =  "mongodb_/*" 
MongodbChannel.listen( mask5 ) do |topic, items|
  p [:mongodb_, mask5, topic, items]
end

i  =  0
while  true
  sleep  1
  i  +=  1
  now  =  Time.now.to_s
  ObserverChannel.notify  "observer/#{i}",  at: now
  DrubyChannel.notify     "druby___/#{i}",  at: now
  MqttChannel.notify      "mqtt____/#{i}",  at: now
  RedisChannel.notify     "redis___/#{i}",  at: now
  MongodbChannel.notify   "mongodb_/#{i}",  at: now
end
