require  "drb/drb"
require  "json"

module MessageChannel

  class Druby

    class Broker
      def initialize
        @mutex  =  Mutex.new
        @patterns  =  {}
      end

      def subscribe( pattern )
        queue  =  Queue.new
        queue_id  =  queue.object_id
        @mutex.synchronize do
          @patterns[queue_id]  =  [pattern, queue]
        end
        queue_id
      end

      def unsubscribe( queue_id )
        @mutex.synchronize do
          @patterns.delete( queue_id )    rescue  nil
        end
      rescue
        nil
      end

      def wait( queue_id )
        @patterns[queue_id].last.pop
      end
      
      def fetch( pattern )
        queue  =  Queue.new
        queue_id  =  queue.object_id
        @mutex.synchronize do
          @patterns[queue_id]  =  [pattern, queue]
        end
        topic, items  =  * queue.pop
      rescue
        nil
      ensure
        @mutex.synchronize do
          @patterns.delete( queue_id )    rescue  nil
        end
      end

      def publish( topic, message )
        @mutex.synchronize do
          @patterns.each do |_queue_id, items|
            pattern, queue  =  *items
            if File.fnmatch( pattern, topic, File::FNM_PATHNAME )
              queue.push( [topic, message] )
            end
          end
        end
      end
    end

    class Agent
      def initialize( host: @@host, port: @@port )
        @@host  =  host
        @@port  =  port
        @uri  =  "druby://#{host}:#{port}"
 
        if  !defined?( @@Broker )  ||  @@Broker.nil?
          @@Broker  =  Broker.new
          DRb.start_service( @uri, @@Broker )    rescue nil
        end
 
        @drb  =  DRbObject.new_with_uri( @uri )
        @queue_ids  =  {}
      end

      def listen_once( pattern )
        topic, message  =  * @drb.fetch( pattern )
      end

      def listen_each( pattern, &block )
        queue_id  =  @drb.subscribe( pattern )
        @queue_ids[pattern]  =  queue_id
        while  true
          topic, message  =  * @drb.wait( queue_id )
          break    if  topic.nil?
          block.call( topic, message )
        end
      rescue => error
        nil
      ensure
        @drb.unsubscribe( queue_id )
        @queue_ids.delete( pattern )    rescue  nil
      end

      def unlisten( pattern )
        if ( queue_id  =  @queue_ids[pattern] )
          @drb.unsubscribe( queue_id )
          @queue_ids.delete( pattern )    rescue  nil
        end
      end

      def notify( topic, message )
        @drb.publish( topic, message )
      end
    end

    attr_reader  :host, :port

    def initialize( host: nil, port: nil )
      @host  =  host  || "127.0.0.1"
      @port  =  ( port  ||  8787 ).to_i
      @agent  =  Agent.new( host: @host, port: @port )
      @threads  =  {}
    end

    def listen_once( *patterns )
      queue  =  Queue.new
      threads  =  {}
      patterns.each do |pattern|
        threads[pattern]  =  Thread.start( pattern ) do |pttrn|
          agent  =  Agent.new
          begin
            topic, message  =  * agent.listen_once( pttrn )
            items  =  JSON.parse( message, symbolize_names: true )
            queue.push( [topic, items] )
          rescue => error
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
    rescue
      nil
    end

    def listen_each( *patterns, &block )
      patterns.each do |pattern|
        @threads[pattern]  =  Thread.start( pattern ) do |pttrn|
          begin
            @agent.listen_each( pttrn ) do |topic, message|
              items  =  JSON.parse( message, symbolize_names: true )
              block.call( topic, items )
            end
          rescue => error
            nil
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
        @agent.unlisten( pattern )
        @threads.delete( pattern )
      end
    end

    def notify( topic, **items )
      @agent.notify( topic, items.to_json )
    end

  end

end

