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
    [ MessageChannel::Mongodb,  "mongodb"                                                     ],
    [ MessageChannel::Mongodb,  "mongodb://127.0.0.1"                                         ],
    [ MessageChannel::Mongodb,  "mongodb://127.0.0.1:27017"                                   ],
    [ MessageChannel::Mongodb,  "mongodb://127.0.0.1:27017/test"                              ],
    [ MessageChannel::Mongodb,  "mongodb://127.0.0.1:27017/test?size=8000"                    ],
    [ MessageChannel::Mongodb,  "mongodb://127.0.0.1:27017/test?name=_event_queue"            ],
    [ MessageChannel::Mongodb,  "mongodb://127.0.0.1:27017/test?size=8000&name=_event_queue"  ],
  ].each do |klass, uri|
    it ["#listen with block", uri] do
      channel  =  MessageChannel.new( uri )

      channel.listen( "hello" ) do |topic, items|
        p [topic, items]
        expect( topic ).to  eq( "hello" )
        expect( Time.parse(items[:at]).class ).to  eq( Time )
      end
      sleep  1

      channel.notify( "hello",  at: Time.now.to_s )
      sleep  1
    end
  end

end
