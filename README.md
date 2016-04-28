# MarkdownRubyDocumentation

Gem provides the ability to use markdown and ruby ERB with some helper methods inside of comments. The comment area then can be generated into a markdown file.

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

#### `print_method_source(method)`
The source of a method block returned as text.

#### `eval_method(method)`
The result of evaluating a method.

#### `print_mark_doc_from(method)`
Prints out the mark doc from another method.

#### `print_raw_comment(method)`
Prints out any comments proceeding a method def.

#### `git_hub_method_url(method)`
Creates a url to the method location on GitHub based on the current sha or it defaults to master.

##### `git_hub_file_url(file_path || Class)`
Creates a url to the file on GitHub based on the current sha or it defaults to master.


##### Example method reference inputs

* ".class_method_name" class method in the current scope.
* "Constant.class_method_name" class method on a specific constant.
* "SomeClass#instance_method_name" an instance method on a specific constant.
* "#instance_method_name" an instance method in the current scope.
    * `__method__` returns `#<current_method_name>`

#### `ruby_to_markdown`
Converts case statements and if statements to bulleted markdown
 **option 1**
   * param [String] ruby_source
   * param [Hash] disable_processors (optional) See processors list.
   *example ruby_to_markdown "def method_name\n'hello'\nend", readable_ruby_numbers: false**
 **option 2 - Assumes methods source of current method**
   * param [Hash] disable_processors (optional) See processors list.
   *example ruby_to_markdown readable_ruby_numbers: false*
   
**processors**
* readable_ruby_numbers
* pretty_early_return
* convert_early_return_to_if_else
* ternary_to_if_else
* ruby_if_statement_to_md
* ruby_case_statement_to_md
* ruby_operators_to_english
* methods_as_local_links
* remove_end_keyword
* constants_with_name_and_value
* remove_memoized_vars


#### `format_link`
format_link "#i_do_other_things" => [I do other things](#i-do-other-things)
format_link "The method 10", "#i_do_other_things" => [The method 10](#i-do-other-things)

Instance method that call other methods will results in an error.

#### `methods_as_local_links`
methods_as_local_links("i_return_one + i_return_two") => "^`i_return_one` + ^`i_return_two`"

#### `constants_with_name_and_value`
constants_with_name_and_value("SOME_CONST_VALUE") => "`SOME_CONST_VALUE => "1"`"

#### `readable_ruby_numbers`
Add commas to any ruby numbers. To provide additional formatting it yields a block given the number object.

#### `hash_to_markdown_table(hash, key_name:, value_name:)`

#### `array_to_markdown_table(array, key_name:)`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/business_rule_documentation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

