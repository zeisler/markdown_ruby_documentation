# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'markdown_ruby_documentation/version'

Gem::Specification.new do |spec|
  spec.name          = "markdown_ruby_documentation"
  spec.version       = MarkdownRubyDocumentation::VERSION
  spec.authors       = ["Dustin Zeisler"]
  spec.email         = ["dustin@zeisler.net"]

  spec.summary       = %q{Allows creating business or technical documentation that can stays automatically in sync with Ruby Logic and available data.}
  spec.description   = %q{Documentation DSL that provides method level comments and links or imports to other comments.
Comments can be written in MarkDown format and the current method can be transformed from Ruby code into a MarkDown readable format.
Static instance, class methods, and constants can be called and used inside of ERB tags.
All defined areas are generated into markdown file per class.}
  spec.homepage      = "https://github.com/zeisler/markdown_ruby_documentation"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.1"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "method_source", "~> 0.8.2"
  spec.add_runtime_dependency "activesupport", ">= 4.1"
  spec.add_runtime_dependency "ruby-progressbar", "~> 1.7"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
end
