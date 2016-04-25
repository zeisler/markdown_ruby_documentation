# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'markdown_ruby_documentation/version'

Gem::Specification.new do |spec|
  spec.name          = "markdown_ruby_documentation"
  spec.version       = MarkdownRubyDocumentation::VERSION
  spec.authors       = ["Dustin Zeisler"]
  spec.email         = ["dustin@zeisler.net"]

  spec.summary       = %q{Gem provides the ability to use markdown and ruby ERB with some helper methods inside of comments}
  spec.description   = %q{Gem provides the ability to use markdown and ruby ERB with some helper methods inside of comments. The comment area then can be generated into a markdown file.}
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
