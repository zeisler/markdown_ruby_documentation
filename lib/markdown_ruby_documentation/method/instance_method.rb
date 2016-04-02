module MarkdownRubyDocumentation
  class InstanceMethod < Method
    def self.type_symbol
      "#"
    end

    def type
      :instance_method
    end
  end
end
