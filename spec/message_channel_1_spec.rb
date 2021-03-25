RSpec.describe MessageChannel do
  it "new" do
    expect( MessageChannel.new.class ).to  eq( MessageChannel::Observer )
    expect( MessageChannel::Observer.new.class ).to  eq( MessageChannel::Observer )
    expect( MessageChannel::Druby.new.class ).to  eq( MessageChannel::Druby )
    expect( MessageChannel::Mqtt.new.class ).to  eq( MessageChannel::Mqtt )
    expect( MessageChannel::Redis.new.class ).to  eq( MessageChannel::Redis )
  end

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
  ].each do |klass, url|
    it url do
      expect( MessageChannel.new(url).class ).to  eq( klass )
    end
  end

end
