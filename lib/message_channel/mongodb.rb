require  "mongo"
require  "json"

::Mongo::Logger.logger.level  =  Logger::ERROR

module MessageChannel
  class Mongodb
    SIZE  =  8000
    NAME  =  "_event_queue"

    def initialize( host: nil, port: nil, db: nil, size: nil, name: nil )
      @host  =  host  ||  "127.0.0.1"
      @port  =  ( port  ||  27017 ).to_i
      @db    =  db  ||  "test"
      @size  =  ( size  ||  SIZE ).to_i
      @name  =  name  ||  NAME

      @url   =  "mongodb://#{ @host }:#{ @port }/#{ @db }"
      @client  =  ::Mongo::Client.new( @url )

      @threads  =  {}
      @mutex  =  Mutex.new

      @event_queue  =  get_event_queue
    end

    def get_event_queue
      event_queue  =  @mutex.synchronize do
        if  @client.database.collection_names.include?( @name )
          event_queue  =  @client[ @name ]
        else
          event_queue  =  @client[ @name, capped: true, size: @size ]
          event_queue.create
          now  =  Time.now
          doc  =  {
            topic: "reset",
            at: now.strftime("%Y%m%d.%H%M%S.%6L"),
          }
          event_queue.insert_one( doc )
          event_queue
        end
      end
    end

    def get_event_tail( event_queue )
      filter  =  {}
      if  enum  =  event_queue.find( {}, { sort: { "$natural" => -1 } } ).to_enum
        if  doc  =  enum.next    rescue  nil
          filter  =  { "_id"=>{ "$gt"=>doc["_id"] } }
        end
      end
      event_tail  =  event_queue.find( filter, { cursor_type: :tailable_await } ).to_enum
    end

    def listen_once( *patterns )
      queue  =  Queue.new
      threads  =  {}
      patterns.each do |pattern|
        threads[pattern]  =  ::Thread.start(pattern) do |pattern|
          event_queue  =  get_event_queue
          event_tail  =  get_event_tail( event_queue )
          begin
            while  doc  =  event_tail.next
              items  =  JSON.parse( doc.to_json, symbolize_names: true )
              topic  =  items[:topic]
              if File.fnmatch( pattern, topic, File::FNM_PATHNAME )
                items.delete( :_id )
                items.delete( :topic )
                queue.push  [topic, items]
              end
            end
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
          begin
            event_queue  =  get_event_queue
            event_tail  =  get_event_tail( event_queue )
            while  doc  =  event_tail.next
              items  =  JSON.parse( doc.to_json, symbolize_names: true )
              topic  =  items[:topic]
              if File.fnmatch( pattern, topic, File::FNM_PATHNAME )
                items.delete( :_id )
                items.delete( :topic )
                block.call( topic, items )
              end
            end
          ensure
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
      items[:topic]  =  topic
      @event_queue.insert_one( items )
    end

  end

end

