RSpec.describe MarkdownRubyDocumentation::MarkdownPresenter do

  let(:summary) { instance_double(MarkdownRubyDocumentation::Summary, title: "My Model Name", summary: "My Summary") }

  it do
    result = described_class.new(title_key: "my_model_name",
                                 summary:   summary,
                                 items:     {
                                   method2: {
                                     text:          "{:key=>\"fun\"}",
                                     method_object: MarkdownRubyDocumentation::InstanceMethod.new("")
                                   },
                                   method4: {
                                     text:          "```ruby\n[1,\n 2,\n 3,\n 0]\n```",
                                     method_object: MarkdownRubyDocumentation::NullMethod.new("")
                                   },
                                   method3: {
                                     text:          "Im method 5",
                                     method_object: MarkdownRubyDocumentation::InstanceMethod.new("")
                                   },
                                 }).call
    expect(result).to eq <<~TEXT
      # My Model Name
      My Summary

      ## Method2
      {:key=>"fun"}

      ## Method3
      Im method 5

      ## Reference Values
      ### Method4
      ```ruby
      [1,
       2,
       3,
       0]
      ```

    TEXT
  end

  it "without Reference values" do
    result = described_class.new(title_key: "my_model_name",
                                 summary:   summary,
                                 items:     {
                                   method2: {
                                     text:          "{:key=>\"fun\"}",
                                     method_object: MarkdownRubyDocumentation::InstanceMethod.new("")
                                   },
                                   method3: {
                                     text:          "Im method 5",
                                     method_object: MarkdownRubyDocumentation::InstanceMethod.new("")
                                   },
                                   class_level_comment: {
                                     text: "This is class level!"
                                   }
                                 }).call
    expect(result).to eq <<~TEXT
      # My Model Name
      My Summary

      This is class level!

      ## Method2
      {:key=>"fun"}

      ## Method3
      Im method 5

    TEXT
  end

  it "without any items" do
    result = described_class.new(title_key: "my_model_name",
                                 summary:   summary,
                                 items:     {}).call
    expect(result).to eq ""
  end
end
