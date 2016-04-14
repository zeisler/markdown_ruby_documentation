$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'markdown_ruby_documentation'

def convert_method_hash(input)
  input.each_with_object({}) do |(name, hash), new_hash|
    new_hash[name] = hash[:text]
  end
end
