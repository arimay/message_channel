require_relative 'lib/message_channel/version'

Gem::Specification.new do |spec|
  spec.name          = "message_channel"
  spec.version       = MessageChannel::VERSION
  spec.authors       = ["arimay"]
  spec.email         = ["arima.yasuhiro@gmail.com"]

  spec.summary       = %q{ Wrapper library for publish/subscribe pattern. }
  spec.description   = %q{ Yet another observer pattern wrapper library via Observable, DRb, MQTT, Redis or Mongo. }
  spec.homepage      = "https://github.com/arimay/message_channel"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "mqtt"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "msgpack"
  spec.add_development_dependency "mongo"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
