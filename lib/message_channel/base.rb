module MessageChannel
  module Base

    # uri:
    #  "observer"
    #  "druby://127.0.0.1:8787"
    #  "mqtt://127.0.0.1:1883"
    #  "redis://127.0.0.1:6379/0"

    def new( uri = nil, type: nil, host: nil, port: nil, db: nil )
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
      end
    end

  end
end

