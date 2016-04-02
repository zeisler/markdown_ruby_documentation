RSpec.describe MarkdownRubyDocumentation::MethodLinker do

  let(:given_text) { <<-TEXT
# when owner has `bad_mortgage_payment_history?`
# * then *decline*
# when `data_unavailable?`
#  then *unavailable*
# else
# * *eligible*
# `decision_from_override` OR `decision_from_rule`
# ```This_is``` an important part of the logic
```ruby
2 + 4
```
```javascript
{"abc":"123","xyz":"890"}
# `ReportParser::TransUnion::CreditLiability`
# `ReportParser::TransUnion::CreditLiability#property_secured_debt?`
```
  TEXT
  }

  let(:expected_text) { <<-TEXT
# when owner has [Bad Mortgage Payment History?](#badmortgagepaymenthistory)
# * then *decline*
# when [Data Unavailable?](#dataunavailable)
#  then *unavailable*
# else
# * *eligible*
# [Decision From Override](#decisionfromoverride) OR [Decision From Rule](#decisionfromrule)
# ```This_is``` an important part of the logic
```ruby
2 + 4
```
```javascript
{"abc":"123","xyz":"890"}
# [Report Parser Trans Union Credit Liability](/reportparser::transunion::creditliability)
# [Property Secured Debt?](/report_parser-trans_union-credit_liability#propertysecureddebt)
```
  TEXT
  }

  it do
    expect(described_class.new(section_key: "page_name", root_path: "/").call(given_text)).to eq expected_text
  end

end
