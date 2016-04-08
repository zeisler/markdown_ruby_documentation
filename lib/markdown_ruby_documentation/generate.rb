module MarkdownRubyDocumentation
  class Generate
    # @param [Class] subjects ruby classes to generate documentation from.
    # @param [Proc] output_proc given name: and text: for use in saving the the files.
    def self.run(
      subjects:, output_proc: -> (name:, text:) { { name => text } }
    )
      pages = subjects.map { |subject| Page.new(subject:     subject,
                                                output_proc: output_proc).call }

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
      attr_reader :subject, :output_proc

      def initialize(subject:,
                     methods: subject.instance_methods(false).concat(subject.private_instance_methods(false)),
                     output_proc:)
        @subject     = subject
        @methods     = methods
        @output_proc = output_proc
      end

      def call
        output_proc.call(name:  subject.name,
                         text: run_pipeline(string_pipeline, run_pipeline(methods_pipeline).to_s))
        self
      end

      private
      def methods_pipeline
        [
          TemplateParser.new(subject, @methods),
          RejectBlankMethod,
          GitHubLink.new(subject: subject),
          MarkdownPresenter.new(title: subject.name.titleize, title_key: section_key),
        ]
      end

      def string_pipeline
        [
          MethodLinker.new(section_key: section_key, root_path: "./"),
        ]
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
