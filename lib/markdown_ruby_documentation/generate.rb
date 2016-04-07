module MarkdownRubyDocumentation
  class Generate
    # @param [Class] subjects ruby classes to generate documentation from.
    # @param [Proc] output_proc given subject_name: and markdown_text: for use in saving the the files.
    def self.run(
          subjects:,
          output_proc: -> (subject_name:, markdown_text:) { { subject_name => markdown_text } }
        )
      subjects.map { |subject| Page.new(subject:      subject,
                                        output_proc:  output_proc).call }

    end

    class Page
      def initialize(subject:,
                     methods: subject.public_instance_methods(false),
                     output_proc:)
        @subject      = subject
        @methods      = methods
        @output_proc  = output_proc
      end

      def call
        output_proc.call(subject_name:  subject.name,
                         markdown_text: run_pipeline(string_pipeline, run_pipeline(methods_pipeline).to_s))
      end

      private
      attr_reader :subject, :output_proc

      def methods_pipeline
        [
          TemplateParser.new(subject, @methods),
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
