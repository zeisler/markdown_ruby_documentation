module MarkdownRubyDocumentation
  class Generate
    # @param [Class] subjects ruby classes to generate documentation from.
    # @param [Proc] output_proc given name: and text: for use in saving the the files.
    def self.run(
      subjects:, erb_methods: DefaultErbMethods, output_proc: -> (name:, text:) { { name => text } }
    )
      erb_methods_class = Class.new
      erb_methods_class.extend TemplateParser::CommentMacros
      erb_methods_class.extend erb_methods
      TemplateParser::CommentMacros.include erb_methods
      pages = subjects.map { |subject| Page.new(subject:           subject,
                                                output_proc:       output_proc,
                                                erb_methods_class: erb_methods_class).call }

      pages.each_with_object({}) do |page, hash|
        name_parts      = page.subject.name.split("::")
        name            = name_parts.pop
        namespace       = name_parts.join("::")
        hash[namespace] ||= {}
        hash[namespace].merge!({ name => page })
        hash
      end
    end

    class Page
      attr_reader :subject, :output_proc, :erb_methods_class

      def initialize(subject:,
                     methods: [],
                     output_proc:,
                     erb_methods_class:)
        if methods.empty?
          instance_m = subject.instance_methods(false).concat(subject.private_instance_methods(false))
          klass_m    = subject.methods(false).concat(subject.private_methods(false)) - Object.methods
          methods.concat instance_m.map { |method| InstanceMethod.new("#{subject.name}##{method}") }
          methods.concat klass_m.map { |method| ClassMethod.new("#{subject.name}.#{method}") }
        else
          methods.map! { |method| method.is_a?(Symbol) ? InstanceMethod.new("#{subject.name}##{method}") : method }
        end
        @erb_methods_class = erb_methods_class
        @subject     = subject
        methods      = methods.map { |method| method.is_a?(Symbol) ? InstanceMethod.new("#{subject.name}##{method}") : method }
        @methods     = methods
        @output_proc = output_proc
      end

      def call
        puts subject.inspect
        methods_pipes = run_pipeline(methods_pipeline)
        text          = run_pipeline(string_pipeline, methods_pipes)
        output_proc.call(name: subject.name,
                         text: text)
        self
      end

      private
      def methods_pipeline
        [
          TemplateParser.new(subject, @methods),
          RejectBlankMethod,
          GitHubLink.new(subject: subject),
          ConstantsPresenter.new(subject),
          MarkdownPresenter.new(title: title, summary: summary, title_key: section_key),
        ]
      end

      def string_pipeline
        [
          MethodLinker.new(section_key: section_key, root_path: "./"),
        ]
      end

      def title
        ancestors = subject.ancestors.select do |klass|
          klass.is_a?(Class) && ![BasicObject, Object, subject].include?(klass)
        end
        [format_class(subject), *ancestors.map { |a| create_link_up_one_level(a) }].join(" < ")
      end

      def format_class(klass)
        klass.name.titleize.split("/").last
      end

      def summary
        descendants       = ObjectSpace.each_object(Class).select { |klass| klass < subject }
        descendants_links = descendants.map { |d| create_link_up_one_level(d) }.join(", ")
        "Descendants: #{descendants_links}" if descendants.count >= 1
      end

      def create_link_up_one_level(klass)
        erb_methods_class.link_to_markdown(klass.to_s, title: format_class(klass))
      end

      def run_pipeline(pipeline, last_result=nil)
        last_result ||= pipeline.shift.call
        pipeline.each do |pipe|
          last_result = pipe.call(last_result)
        end
        last_result
      end

      def section_key
        subject.name.underscore.gsub("/", "-")
      end
    end
  end
end
