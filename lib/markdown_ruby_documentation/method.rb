module MarkdownRubyDocumentation
  class Method
    InvalidMethodReference = Class.new(StandardError)
    attr_reader :method_reference, :visibility
    protected :method_reference

    def initialize(method_reference, context: Kernel, visibility: :public)
      @method_reference = method_reference.to_s
      @context          = context
      @visibility = visibility
    end

    # @param [String] method_reference
    # @example
    #   ".class_method_name" class method in the current scope.
    #   "Constant.class_method_name" class method on a specific constant.
    #   "SomeClass#instance_method_name" an instance method on a specific constant.
    #   "#instance_method_name" an instance method in the current scope.
    def self.create(method_reference, null_method: false, context: Kernel, visibility: :public)
      return method_reference if method_reference.is_a?(Method)
      case method_reference
      when InstanceMethod
        InstanceMethod.new(method_reference, context: context, visibility: visibility)
      when ClassMethod
        ClassMethod.new(method_reference, context: context, visibility: visibility)
      else
        if null_method
          NullMethod.new(method_reference, context: context, visibility: visibility)
        else
          raise InvalidMethodReference, "method_reference is formatted incorrectly: '#{method_reference}'"
        end
      end
    end

    def ==(other_method)
      self.class == other_method.class && other_method.method_reference == self.method_reference
    end

    alias :eql? :==

    def hash
      @method_reference.hash
    end

    def self.===(value)
      if value.is_a?(String)
        value.include?(type_symbol) && !!/\A[:A-Za-z_0-9!?#{type_symbol}]+\z/.match(value)
      else
        super
      end
    end

    # @return [String]
    def type_symbol
      self.class.type_symbol
    end

    # @return [Class]
    def context
      if method_reference.start_with?(type_symbol)
        @context
      else
        constant = method_reference.split(type_symbol).first
        begin
          constant.constantize
        rescue NameError => e
          @context.const_get(constant)
        end
      end
    end

    def context_name
      if method_reference.start_with?(type_symbol)
        @context.name
      else
        method_reference.split(type_symbol).first
      end
    end

    # @return [Symbol]
    def name
      method_reference.split(type_symbol).last.try!(:to_sym)
    end

    # @return [String]
    def to_s
      method_reference
    end

    # @return [String]
    def inspect
      "#<#{self.class.name} #{to_s}>"
    end

    # @return [Proc]
    def to_proc
      context.public_send(type, name)
    end

    def type
      raise NotImplementedError
    end
  end
end
