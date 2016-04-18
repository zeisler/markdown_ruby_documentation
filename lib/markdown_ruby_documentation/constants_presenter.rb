module MarkdownRubyDocumentation
  class ConstantsPresenter

    attr_reader :subject

    def initialize(subject)
      @subject = subject
    end

    def call(interface)
      constants.each do |const_name, value|
        interface[const_name] = { text: value, method_object: Method.create("#{subject.name}::#{const_name}", null_method: true) }
      end
      interface
    end

    private

    def constants
      subject.constants.each_with_object({}) do |v, const|
        c        = subject.const_get(v)
        const[v] = format(c) unless c.class == Module || c.class == Class
      end
    end

    def format(value)
      case value
      when Fixnum
        ActiveSupport::NumberHelper.number_to_delimited(value)
      when String
        value.inspect
      else
        value
      end
    end

  end
end
