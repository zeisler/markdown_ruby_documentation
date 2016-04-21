module MarkdownRubyDocumentation
  class InstanceToClassMethods
    attr_reader :method_object

    def initialize(method:)
      @method_object = method
    end

    def eval_instance_method
      _module = method_object.context.const_set(new_class_name, Class.new(method_object.context))
      rescue_and_define_method(_module) do |_module|
        create_method(method_object, _module)
        _module.send(method_object.name)
      end
    end

    private

    def new_class_name
      "InstanceToClassMethods#{method_object.context.name}#{('A'..'Z').to_a.sample(5).join}".delete("::")
    end

    def rescue_and_define_method(_module, &block)
      block.call(_module)
    rescue NameError => e
      if (undefined_method = e.message.match(/undefined local variable or method `(.+)'/).try!(:captures).try!(:first))
        undefined_method = Method.create("##{undefined_method}", context: method_object.context)
        create_method(undefined_method, _module)
        rescue_and_define_method(_module, &block)
      else
        raise e
      end
    end

    def create_method(method, m=Module.new)
      m.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{method.name}
      #{PrintMethodSource.new(method: method).print}
            end
      RUBY
      m
    end
  end
end
