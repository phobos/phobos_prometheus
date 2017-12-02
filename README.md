# Phobos Prometheus

A bundled Prometheus collector and exporter of Phobos metrics.

Exporter is a simple Sinatra app which can be mounted in eg a Rack App.

Collector initializes Prometheus metrics and sets up a subscribtion to certain Phobos events to keep
monitor of your metrics

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'phobos_prometheus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install phobos_prometheus

## Usage

In phobos_boot.rb, add `PhobosPrometheus.register_subscriber` to setup tracking of Phobos metrics.

In config.ru, mount the metrics endpoint:

```ruby
run Rack::URLMap.new(
    '/metrics' => PhobosPrometheus::Exporter,
    # ...
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/phobos_prometheus.
