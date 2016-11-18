module MarkdownRubyDocumentation
  class ConstantsPresenter

    attr_reader :subject

    def initialize(subject)
      @subject = subject
    end

    def call(interface)
      constants.each do |const_name, value|
        next if value.nil?
        interface[const_name] = { text: value, method_object: Method.create("#{subject.name}::#{const_name}", null_method: true) }
      end
      interface
    end

    def self.format(value)
      case value
      when Fixnum
        ActiveSupport::NumberHelper.number_to_delimited(value)
      when String
        value.inspect
      else
        if value.to_s =~ /#<[a-zA-Z0-9\-_:]+:[0-9xa-f]+>/
          nil
        else
          value
        end
      end
    end

    private

    def constants
      subject.constants.each_with_object({}) do |v, const|
        c        = subject.const_get(v)
        const[v] = self.class.format(c) unless [Regexp, Module, Class].include?(c.class)
      end
    end
  end
end
