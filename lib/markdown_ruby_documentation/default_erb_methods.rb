module MarkdownRubyDocumentation
  module DefaultErbMethods
    def link_to_markdown(klass, title:)
      "[#{title}](#{klass})"
    end

    def self.erb_methods_module
      self
    end
  end
end
