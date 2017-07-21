RSpec.describe MarkdownRubyDocumentation::GitHubLink do

  class GitHubLinkTest
    def test1
    end

    def test2
    end
  end

  it do
    result = described_class.new(subject:  GitHubLinkTest,
                                 base_url: "https://github.com/zeisler/this_project")
               .call({ :test1 => { text: "" }, :test2 => { text: "" } })
    expect(result).to eq({ :test1 => { text: "\n\n[show on github](https://github.com/zeisler/this_project/blob/#{MarkdownRubyDocumentation::GitHubProject.branch}/spec/markdown_ruby_documentation/git_hub_link_spec.rb#L4)" },
                           :test2 => { text: "\n\n[show on github](https://github.com/zeisler/this_project/blob/#{MarkdownRubyDocumentation::GitHubProject.branch}/spec/markdown_ruby_documentation/git_hub_link_spec.rb#L7)" } })
  end
end
