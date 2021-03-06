require  "redis"
require  "json"
require  "timeout"

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
        threads[pattern]  =  ::Thread.start( pattern ) do |pttrn|
          redis  =  ::Redis.new( host: @host, port: @port, db: @db )
          begin
            redis.psubscribe( pttrn ) do |on|
              on.pmessage do |ptn, channel, message|
                items  =  JSON.parse( message, symbolize_names: true )
                redis.punsubscribe( ptn )    rescue  nil
                queue.push  [channel, items]
              end
            end
          rescue  ::Redis::BaseConnectionError => error
            sleep 1
            retry
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
          redis  =  ::Redis.new( host: @host, port: @port, db: @db )
          begin
            redis.psubscribe( pttrn ) do |on|
              on.pmessage do |_ptn, channel, message|
                items  =  JSON.parse( message, symbolize_names: true )
                block.call( channel, items )
              end
            end
          rescue  ::Redis::BaseConnectionError => error
            sleep 1
            retry
          ensure
            redis.punsubscribe( pttrn )    rescue  nil
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
      @redis.publish( topic, items.to_json )
    end

  end

end

