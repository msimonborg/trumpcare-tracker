# TrumpcareTracker

Uses the Twitter and PYR gems to look at Tweet timelines from US Senators and see how much time they devote to talking about Trumpcare vs. Russia.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trumpcare_tracker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trumpcare_tracker

## Usage

Register your app with Twitter and set the following environment variables corresponding to your Twitter keys
```
TCT_CONSUMER_KEY
TCT_CONSUMER_SECRET
TCT_ACCESS_TOKEN
TCT_ACCESS_TOKEN_SECRET
```
then

```
bundle exec rake export # Audit tweets and export to CSV

bundle exec rake tweet # Audit tweets and post to Twitter timeline with Senator's phone numbers
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/msimonborg/trumpcare-tracker.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

