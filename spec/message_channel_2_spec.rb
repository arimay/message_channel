require  "date"
require  "time"

RSpec.describe MessageChannel do

  [
    [ MessageChannel::Observer, "observer"                                                    ],
    [ MessageChannel::Observer, "observer:"                                                   ],
    [ MessageChannel::Druby,    "druby"                                                       ],
    [ MessageChannel::Druby,    "druby:"                                                      ],
    [ MessageChannel::Druby,    "druby://127.0.0.1"                                           ],
    [ MessageChannel::Druby,    "druby://127.0.0.1:8787"                                      ],
    [ MessageChannel::Mqtt,     "mqtt"                                                        ],
    [ MessageChannel::Mqtt,     "mqtt:"                                                       ],
    [ MessageChannel::Mqtt,     "mqtt://127.0.0.1"                                            ],
    [ MessageChannel::Mqtt,     "mqtt://127.0.0.1:1883"                                       ],
    [ MessageChannel::Redis,    "redis"                                                       ],
    [ MessageChannel::Redis,    "redis:"                                                      ],
    [ MessageChannel::Redis,    "redis://127.0.0.1"                                           ],
    [ MessageChannel::Redis,    "redis://127.0.0.1:6379"                                      ],
    [ MessageChannel::Redis,    "redis://127.0.0.1:6379/1"                                    ],
  ].each do |klass, uri|
    it ["#listen async", uri] do
      channel  =  MessageChannel.new( uri )

      channel.listen( "hello" ) do |topic, items|
        puts [topic, items].inspect
        expect( topic ).to  eq( "hello" )
        expect( Time.parse(items[:at]).class ).to  eq( Time )
      end
      sleep  1

      channel.notify( "hello",  at: Time.now.to_s )
      sleep  1

      channel.unlisten( "hello" )
    end
  end

end
