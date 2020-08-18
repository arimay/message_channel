require  "message_channel/version"
require  "message_channel/base"

module MessageChannel

  class Error < StandardError; end

  class  <<  self
    include MessageChannel::Base
  end

  autoload  :Observer, "message_channel/observer"
  autoload  :Druby, "message_channel/druby"
  autoload  :Mqtt, "message_channel/mqtt"
  autoload  :Redis, "message_channel/redis"
  autoload  :Mongodb, "message_channel/mongodb"
end

