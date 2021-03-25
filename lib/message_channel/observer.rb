require  "observer"
require  "json"
require  "timeout"

module MessageChannel

  class Observer

    class Agent
      include ::Observable

      def notify( topic, message )
        changed
        notify_observers( topic, message )
      end
    end

    def initialize( **_options )
      @asyncs  =  {}
      @awaits  =  {}
      @queues  =  {}
      @@Agent  ||=  Agent.new
      @@Agent.add_observer( self, :action ) 
    end

    def action( topic, message )
      items  =  JSON.parse( message, symbolize_names: true )
      @asyncs.keys.each do |pattern|
        if File.fnmatch( pattern, topic, File::FNM_PATHNAME )
          if ( action  =  @asyncs[pattern] )
            action.call( topic, items )
          end
        end
      end
      @awaits.keys.each do |queue|
        @awaits[queue].each do |pattern|
          if File.fnmatch( pattern, topic, File::FNM_PATHNAME )
            queue.push( [topic, items] )
          end
        end
      end
    end

    def listen_once( *patterns )
      queue  =  Queue.new
      @awaits[queue]  =  patterns
      topic, items  =  * queue.pop
      @awaits.delete( queue )    rescue nil
      [topic, items]
    end

    def listen_each( *patterns, &block )
      patterns.each do |pattern|
        @asyncs[pattern]  =  block
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
        if ( action  =  @asyncs[pattern] )
          @asyncs.delete( pattern )
        end
      end
    end

    def notify( topic, **items )
      @@Agent.notify( topic, items.to_json )
    end

  end

end

