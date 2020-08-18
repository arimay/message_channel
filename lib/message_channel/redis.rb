require  "redis"
require  "json"

module MessageChannel
  class Redis

    def initialize( host: nil, port: nil, db: nil )
      @host  =  host  || "127.0.0.1"
      @port  =  ( port  ||  6379 ).to_i
      @db  =  ( db  ||  0 ).to_i
      @redis  =  ::Redis.new( host: @host, port: @port, db: @db )
      @threads  =  {}
    end

    def listen_once( *patterns )
      queue  =  Queue.new
      threads  =  {}
      patterns.each do |pattern|
        threads[pattern]  =  ::Thread.start(pattern) do |pattern|
          redis  =  ::Redis.new( host: @host, port: @port, db: @db )
          begin
            redis.psubscribe( pattern ) do |on|
              on.pmessage do |pattern, channel, message|
                items  =  JSON.parse( message, symbolize_names: true )
                redis.punsubscribe( topic )    rescue  nil
                queue.push  [channel, items]
              end
            end
          rescue  ::Redis::BaseConnectionError => error
            sleep 1
            retry
          ensure
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
        @threads[pattern]  =  ::Thread.start(pattern) do |pattern|
          redis  =  ::Redis.new( host: @host, port: @port, db: @db )
          begin
            redis.psubscribe( pattern ) do |on|
              on.pmessage do |pattern, channel, message|
                items  =  JSON.parse( message, symbolize_names: true )
                block.call( channel, items )
              end
            end
          rescue  ::Redis::BaseConnectionError => error
            sleep 1
            retry
          ensure
            redis.punsubscribe( topic )    rescue  nil
          end
        end
      end
    end

    def listen( *patterns, &block )
      if block.nil?
        listen_once( *patterns )
      else
        listen_each( *patterns ) do |topic, items|
          block.call( topic, items )
        end
      end
    end

    def unlisten( **patterns )
      patterns.each do |pattern|
        @threads[pattern].kill    rescue  nil
        @threads.delete( pattern )    rescue  nil
      end
    end

    def notify( topic, **items )
      @redis.publish( topic, items.to_json )
    end

  end

end

