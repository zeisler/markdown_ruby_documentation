module MarkdownRubyDocumentation
  class ClassMethod < Method

    def self.type_symbol
      "."
    end

    def type
      :method
    end

  end
end
