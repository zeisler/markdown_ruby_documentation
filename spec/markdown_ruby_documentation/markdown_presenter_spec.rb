RSpec.describe MarkdownRubyDocumentation::MarkdownPresenter do

  let(:summary){instance_double(Summary, title: "My Model Name", summary: "My Summary")}

  it do
    result = described_class.new(title_key: "my_model_name",
                                 summary:   summary,
                                 items:     { method2: { text: "{:key=>\"fun\"}" },
                                              method3: { text: "Im method 5" },
                                              method4: { text: "```ruby\n[1,\n 2,\n 3,\n 0]\n```" } }).call
    expect(result).to eq <<~TEXT
      # My Model Name
      My Summary

      ## Method2
      {:key=>"fun"}

      ## Method3
      Im method 5

      ## Method4
      ```ruby
      [1,
       2,
       3,
       0]
      ```
    TEXT
  end
end
