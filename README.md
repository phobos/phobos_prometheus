[![Build Status](https://travis-ci.org/phobos/phobos_prometheus.svg?branch=master)](https://travis-ci.org/phobos/phobos_prometheus)
[![Maintainability](https://api.codeclimate.com/v1/badges/c6dfe9affb0e7cc5a682/maintainability)](https://codeclimate.com/github/phobos/phobos_prometheus/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/c6dfe9affb0e7cc5a682/test_coverage)](https://codeclimate.com/github/phobos/phobos_prometheus/test_coverage)
[![Chat with us on Discord](https://discordapp.com/api/guilds/379938130326847488/widget.png)](https://discord.gg/rfMUBVD)

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

**Step 1:** In phobos_boot.rb, configure the library by calling `PhobosPrometheus.configure` with
the path of your configuration file. Note that PhobosPrometheus expects Phobos.configure to have
been run since it is using Phobos.logger

```ruby
PhobosPrometheus.configure('config/phobos_prometheus.yml')
```

**Step 2:** In phobos_boot.rb, add `PhobosPrometheus.subscribe` to setup tracking of Phobos metrics.

**Step 3:** In config.ru, mount the metrics endpoint:

```ruby
run Rack::URLMap.new(
    '/metrics' => PhobosPrometheus::Exporter,
    # ...
)
```

## Configuration

There are three major keys to consider: `counters`, `histograms` and `buckets`. You probably also
want to update `metrics_prefix` to differentiate between different consumer apps.

For a list of possible instrumentation events, see Phobos and PhobosDBCheckpoint.

### Counters

The `counters` section provides a list of instrumentation labels that you want to create counters
for. For example, in order to count the number of processed events:

```yml
counters:
  - instrumentation: listener.process_message
```

### Histograms

The `histograms` section provides a list of instrumentation labels that you want to create
histograms for. Histograms are a bit more complex as they require bin sizes, these can be named and referenced via `bucket_name`

For example, in order to count the duration of processed events:

```yml
histograms:
  - instrumentation: listener.process_message
    bucket_name: message
```

The example above assumes you have defined a bucket with name `message`, see below.

### Buckets

The `buckets` section provides a definition of bucket sizes having named labels that you need to
reference for configuring histograms.

To connect with the bucket example above, we need to create a bucket named `message` e.g:

```yml
buckets:
  - name: message
    bins:
      - 5
      - 10
      - 25
      # - ...
```

### Gauges

The `gauges` section provides a list of bi-directional gauges. The provided `label` will be used as the prometheus label, and a counter with this label will be incremented on any event matching the instrumentation label given in `increment` and decremented by events matching `decrement`.

In order to count the number of active handlers, one could do this:

```yml
gauges:
  - label: number_of_handlers
    increment: listener.start_handler
    decrement: listener.stop_handler
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to
run the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/phobos/phobos_prometheus.
