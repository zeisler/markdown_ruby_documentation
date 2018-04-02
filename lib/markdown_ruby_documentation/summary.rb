module MarkdownRubyDocumentation
  class Summary
    attr_reader :erb_methods_class, :subject

    def initialize(subject:, erb_methods_class:)
      @subject           = subject
      @erb_methods_class = erb_methods_class
    end

    def title
      [format_class(subject), *ancestors_links].join(" < ")
    end

    def summary
      "Descendants: #{descendants_links.join(", ")}" if descendants.present?
    end

    private

    def ancestors_links
      ancestors.map(&method(:create_link))
    end

    def descendants_links
      descendants.map(&method(:create_link))
    end

    def descendants
      @descendants ||= begin
        ObjectSpace.each_object(Class).select do |klass|
          klass.try!(:name) && klass < subject && !(klass.name.to_s.include?("InstanceToClassMethods"))
        end.sort_by(&:name)
      end
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
