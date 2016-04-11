module MarkdownRubyDocumentation
  class Method
    attr_reader :method_reference
    private :method_reference

    def initialize(method_reference)
      @method_reference = method_reference
    end

    # @param [String] method_reference
    # @example
    #   ".class_method_name" class method in the current scope.
    #   "Constant.class_method_name" class method on a specific constant.
    #   "SomeClass#instance_method_name" an instance method on a specific constant.
    #   "#instance_method_name" an instance method in the current scope.
    def self.create(method_reference, null_method: false)
      case method_reference
      when InstanceMethod
        InstanceMethod.new(method_reference)
      when ClassMethod
        ClassMethod.new(method_reference)
      else
        if null_method
          NullMethod.new(method_reference)
        else
          raise ArgumentError, "method_reference is formatted incorrectly: '#{method_reference}'"
        end
      end
    end

    def self.===(value)
      if value.is_a?(String)
        value.include?(type_symbol)
      else
        super
      end
    end

    # @return [String]
    def type_symbol
      self.class.type_symbol
    end

    # @return [Symbol]
    def context
      if method_reference.start_with?(type_symbol)
        :ruby_class
      else
        method_reference.split(type_symbol).first.try!(:to_sym)
      end
    end

    # @return [Symbol]
    def name
      method_reference.split(type_symbol).last.try!(:to_sym)
    end

    # @return [String]
    def to_s
      method_reference.to_s
    end
  end
end
