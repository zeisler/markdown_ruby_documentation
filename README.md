# MarkdownRubyDocumentation

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/business_rule_documentation`. To experiment with that code, run `bin/console` for an interactive prompt.

Gem provides the ability to use markdown and ruby ERB with some helper methods inside of comments. The comment area then can be generated into a html page.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'markdown_ruby_documentation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install markdown_ruby_documentation

## Usage

```ruby
class RubyClassToBeInspected
  MY_VALUE = 10

  #=mark_doc
  # **I am Documentation**
  # <%= print_method_source "#i_am_a_documented_method" %>
  # ^`MY_VALUE`
  #=mark_end
  def i_am_a_documented_method
    "Hello"
  end
end

html_generator  = MarkdownRubyDocumentation::HtmlGenerator.new(
  dir: <Output Directory>
)

MarkdownRubyDocumentation::Generate.run(
  subjects:     [RubyClassToBeInspected], 
  output_proc:  html_generator
).call
```

### Resulting file

```markdown
# Ruby Class To Be Inspected

## I am a documented method

**I am Documentation**
"Hello"
[MY_VALUE](/ruby_class_to_be_inspected#my_value)

```

### ERB Methods

#### `print_method_source`
The source of a method block returned as text.

#### `eval_method`
The result of evaluating a method.

#### `print_mark_doc_from`
Prints out the mark doc from another method.

#### `print_raw_comment`
Prints out any comments proceeding a method def.

#### `git_hub_method_url`
Creates a url to GitHub based on the current sha or it defaults to master.

##### Example inputs

* ".class_method_name" class method in the current scope.
* "Constant.class_method_name" class method on a specific constant.
* "SomeClass#instance_method_name" an instance method on a specific constant.
* "#instance_method_name" an instance method in the current scope.

Instance method that call other methods will results in an error.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/business_rule_documentation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

