
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'phobos_prometheus/version'

Gem::Specification.new do |spec|
  spec.name          = 'phobos_prometheus'
  spec.version       = PhobosPrometheus::VERSION
  spec.authors       = ['Mathias Klippinge']
  spec.email         = ['mathias.klippinge@gmail.com']

  spec.summary       = 'Prometheus collector for Phobos'
  spec.description   = 'Gathers metrics from Phobos, making it possible for Prometheus server to consume this'
  spec.homepage      = 'https://github.com/klarna/phobos_prometheus'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'prometheus-client'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop_rules'
end
