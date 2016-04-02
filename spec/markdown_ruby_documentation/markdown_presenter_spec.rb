RSpec.describe MarkdownRubyDocumentation::MarkdownPresenter do

  it do
    result = described_class.new(title:     "My Model Name",
                                 title_key: "my_model_name",
                                 items:     { method2: "{:key=>\"fun\"}",
                                              method3: "Im method 5",
                                              method4: "```ruby\n[1,\n 2,\n 3,\n 0]\n```" }).call
    expect(result).to eq <<~TEXT
      # My Model Name

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
