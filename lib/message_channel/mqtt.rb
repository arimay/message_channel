require  "mqtt"
require  "json"
require  "timeout"

module MessageChannel
  class Mqtt

    def initialize( host: nil, port: nil )
      @host  =  host  || "127.0.0.1"
      @port  =  ( port  ||  1883 ).to_i
      @mqtt  =  MQTT::Client.connect( @host, @port )
      @threads  =  {}
    end

    def listen_once( *patterns )
      queue  =  Queue.new
      threads  =  {}
      patterns.each do |pattern|
        threads[pattern]  =  ::Thread.start( pattern ) do |pttrn|
          mqtt  =  MQTT::Client.connect( @host, @port )
          begin
            mqtt.get( pttrn ) do |topic, message|
              items  =  JSON.parse( message, symbolize_names: true )
              mqtt.disconnect    rescue  nil
              queue.push  [topic, items]
            end
          rescue => e
            nil
          end
        end
      end

      topic, items  =  queue.pop
      patterns.each do |pattern|
        threads[pattern].kill    rescue  nil
        threads.delete( pattern )    rescue  nil
      end
      [topic, items]
    end

    def listen_each( *patterns, &block )
      patterns.each do |pattern|
        @threads[pattern]  =  ::Thread.start( pattern ) do |pttrn|
          mqtt  =  MQTT::Client.connect( @host, @port )
          begin
            mqtt.get( pttrn ) do |topic, message|
              items  =  JSON.parse( message, symbolize_names: true )
              block.call( topic, items )
            end
          ensure
            mqtt.disconnect    rescue  nil
          end
        end
      end
    end

    def listen( *patterns, timeout: nil, &block )
      if block_given?
        listen_each( *patterns ) do |topic, items|
          block.call( topic, items )
        end
        return  nil
      end
      if timeout.nil? || ( timeout.is_a?( Numeric ) && timeout >= 0 )
        begin
          Timeout.timeout( timeout ) do
            listen_once( *patterns )
          end
        rescue  Timeout::Error
          return  nil
        end
      else
        raise  ArgumentError, "timeout: %s" % timeout
      end
    end

    def unlisten( *patterns )
      patterns.each do |pattern|
        @threads[pattern].kill    rescue  nil
        @threads.delete( pattern )    rescue  nil
      end
    end

    def notify( topic, **items )
      @mqtt.publish( topic, items.to_json, false )
    end

  end

end

