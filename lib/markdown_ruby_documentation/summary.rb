class Summary
  attr_reader :erb_methods_class, :subject

  def initialize(subject:, erb_methods_class:)
    @subject           = subject
    @erb_methods_class = erb_methods_class
  end

  def title
    ancestors = subject.ancestors.select do |klass|
      klass.is_a?(Class) && ![BasicObject, Object, subject].include?(klass)
    end
    [format_class(subject), *ancestors.map { |a| create_link(a) }].join(" < ")
  end

  def summary
    descendants = ObjectSpace.each_object(Class).select { |klass| klass < subject && !klass.name.include?("InstanceToClassMethods") }

    descendants_links = descendants.map { |d| create_link(d) }.join(", ")
    "Descendants: #{descendants_links}" if descendants.count >= 1
  end

  private

  def create_link(klass)
    erb_methods_class.link_to_markdown(klass.to_s, title: format_class(klass))
  end

  def format_class(klass)
    klass.name.titleize.split("/").last
  end
end
