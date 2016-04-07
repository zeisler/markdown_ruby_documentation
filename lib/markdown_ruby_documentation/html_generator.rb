require "github/markdown"
require 'github/markup'

module MarkdownRubyDocumentation
  class HtmlGenerator
    GIT_HUB_MD_CSS = Pathname.new(File.join(__dir__, "../github-markdown.css")).realpath
    WRITE_TO_FILE  = -> (name:, text:) { File.open(name, "w").write(text) }
    EXPORT_CSS     = -> (dir:) { FileUtils.cp GIT_HUB_MD_CSS, dir }

    def initialize(dir:, output_proc: WRITE_TO_FILE, resource_output_proc: EXPORT_CSS)
      @dir                  = dir
      @output_proc          = output_proc
      @resource_output_proc = resource_output_proc
    end

    def call(subject_name:, markdown_text:)
      output_proc.call(name: full_path(subject_name), text: gen_html(markdown_text, subject_name))
      resource_output_proc.call(dir: dir)
    end

    private

    attr_reader :dir, :output_proc, :resource_output_proc

    def full_path(subject_name)
      File.join(dir, "#{subject_name.underscore}.html")
    end

    def gen_html(markdown_text, subject_name)
      file = temp_file(subject_name, markdown_text)
      wrap_html(GitHub::Markup.render(file.path, File.open(file.path).read), subject_name)
    end

    def temp_file(subject_name, markdown_text)
      Tempfile.new([subject_name.underscore, ".md"]).tap do |t|
        t.write markdown_text
        t.rewind
      end

    end

    def wrap_html(html, name)
      <<-HTML.strip_heredoc
      <!doctype html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, minimal-ui">
          <title>#{name.titleize}</title>
          <link rel="stylesheet" href="github-markdown.css">
        </head>
        <body>
          <article class="markdown-body">
          #{html}
          </article>
        </body>
      </html>
      HTML
    end
  end
end
