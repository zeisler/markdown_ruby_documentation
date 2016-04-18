module MarkdownRubyDocumentation
  class Generate
    # @param [Class] subjects ruby classes to generate documentation from.
    # @param [Module] erb_methods must contain #link_to_markdown and contain any additional methods for comment ERB
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
        initialize_methods(methods, subject)
        @erb_methods_class = erb_methods_class
        @subject           = subject
        methods            = methods
        @methods           = methods
        @output_proc       = output_proc
      end

      def call
        methods_pipes = run_pipeline(methods_pipeline)
        text          = run_pipeline(string_pipeline, methods_pipes)
        output_proc.call(name: subject.name,
                         text: text)
        self
      end

      private
      def initialize_methods(methods, subject)
        if methods.empty?
          all_instance_and_class_methods(methods, subject)
        else
          methods.map! { |method| method.is_a?(Symbol) ? InstanceMethod.new("#{subject.name}##{method}") : method }
        end
      end

      def all_instance_and_class_methods(methods, subject)
        instance_m = subject.instance_methods(false).concat(subject.private_instance_methods(false))
        klass_m    = subject.methods(false).concat(subject.private_methods(false)) - Object.methods
        methods.concat instance_m.map { |method| InstanceMethod.new("#{subject.name}##{method}") }
        methods.concat klass_m.map { |method| ClassMethod.new("#{subject.name}.#{method}") }
      end

      def methods_pipeline
        [
          TemplateParser.new(subject, @methods),
          RejectBlankMethod,
          GitHubLink.new(subject: subject),
          ConstantsPresenter.new(subject),
          MarkdownPresenter.new(summary: summary, title_key: section_key),
        ]
      end

      def string_pipeline
        [
          MethodLinker.new(section_key: section_key, root_path: "./"),
        ]
      end

      def summary
        @summary ||= Summary.new(subject: subject, erb_methods_class: erb_methods_class)
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
