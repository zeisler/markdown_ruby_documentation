RSpec.describe MarkdownRubyDocumentation::HtmlGenerator do

  let(:temp_dir) { Pathname.new(File.join(__dir__, "../../tmp")).realpath }
  let(:subject_name) { "htmlGenTest" }
  before do
    FileUtils.mkdir_p(temp_dir)
  end

  describe "#call" do
    it "interacts with custom output proc" do
      created_output = {}
      output_proc    = -> (name:, text:) { created_output[name] = text }
      described_class.new(dir: temp_dir, output_proc: output_proc).call(subject_name: subject_name, markdown_text: "### Hello")
      expect(created_output[File.join(temp_dir, "html_gen_test.html")]).to eq <<-HTML.strip_heredoc
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, minimal-ui">
            <title>Html Gen Test</title>
            <link rel="stylesheet" href="github-markdown.css">
          </head>
          <body>
            <article class="markdown-body">
            <h3>Hello</h3>

            </article>
          </body>
        </html>
      HTML
    end

    it "copies resources to given directory" do
      described_class.new(dir: temp_dir).call(subject_name: subject_name, markdown_text: "### Hello")
      expect(File.exists?(File.join(temp_dir, "github-markdown.css"))).to eq true
    end

    it "uses the default write to file proc" do
      expect {
        described_class.new(dir: temp_dir).call(subject_name: subject_name, markdown_text: "### Hello")
      }.to_not raise_error
    end
  end
end
