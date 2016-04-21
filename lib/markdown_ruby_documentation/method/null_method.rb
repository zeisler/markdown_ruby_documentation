module MarkdownRubyDocumentation
  class NullMethod < Method

    def self.type_symbol
      ""
    end

    def name
      nil
    end

    def type
      raise "Does not have a type"
    end

    def to_proc
      raise "Not convertible to a proc"
    end

    def context
      method_reference.constantize
    end

    def context_name
      method_reference
    end
  end
end
