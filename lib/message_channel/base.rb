module MessageChannel
  class Error < StandardError; end

  module Base

    # uri:
    #  "observer"
    #  "druby://127.0.0.1:8787"
    #  "mqtt://127.0.0.1:1883"
    #  "redis://127.0.0.1:6379/0"
    #  "mongodb://127.0.0.1:27017/test?size=4000&name=_event_queue"

    def new( uri = nil, type: nil, host: nil, port: nil, db: nil, size: nil, name: nil )
      if  uri
        uris  =  URI.parse( uri )
        if  uris.scheme.nil?  &&  uris.host.nil?  &&  uris.port.nil?  &&  uris.path
          type  =  uris.path
          params  =  []
        else
          type  =  uris.scheme  ||  type
          host  =  uris.host  ||  host
          port  =  uris.port  ||  port
          params  =  uris.path.gsub(/^\//, "").split('/')
          query  =  Hash[ URI::decode_www_form(uris.query) ]  rescue  {}
          size  =  query[:size]  ||  size
          name  =  query[:name]  ||  name
        end
      else
        parans  =  []
      end

      options  =  { host: host, port: port }

      case  type
      when  "observer", NilClass
        MessageChannel::Observer.new( **options )
      when  "druby"
        MessageChannel::Druby.new( **options )
      when  "mqtt"
        MessageChannel::Mqtt.new( **options )
      when  "redis"
        options[:db]  =  params.shift  ||  db
        MessageChannel::Redis.new( **options )
      when  "mongodb"
        options[:db]  =  params.shift  ||  db
        options[:size]  =  size
        options[:name]  =  name
        MessageChannel::Mongodb.new( **options )
      end
    end

  end
end

