module MarkdownRubyDocumentation
  class Summary
    attr_reader :erb_methods_class, :subject

    def initialize(subject:, erb_methods_class:)
      @subject           = subject
      @erb_methods_class = erb_methods_class
    end

    def title
      [format_class(subject), *ancestors.map { |a| create_link(a) }].join(" < ")
    end

    def summary
      "Descendants: #{descendants_links}" if descendants.count >= 1
    end

    private

    def descendants_links
      descendants.map { |d| create_link(d) }.join(", ")
    end

    def descendants
      @descendants ||= ObjectSpace.each_object(Class).select do |klass|
        klass < subject && !(klass == InstanceToClassMethods)
      end.sort_by(&:name)
    end

    def ancestors
      subject.ancestors.select do |klass|
        klass.is_a?(Class) && ![BasicObject, Object, subject].include?(klass)
      end.sort_by(&:name)
    end

    def create_link(klass)
      erb_methods_class.link_to_markdown(klass.to_s, title: format_class(klass))
    end

    def format_class(klass)
      klass.name.titleize.split("/").last
    end
  end
end
