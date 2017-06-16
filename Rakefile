# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'date'
require 'rubocop/rake_task'
require 'trumpcare_tracker/reporters'
require 'trumpcare_tracker/tweet_bot'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

TrumpcareTracker::Reporters.new

TrumpcareTracker::TweetBot.new('trumpcaretrackr') do
  "#{Date.today.strftime('%A, %B %d %Y')} - "\
    "here's how Senate Democrats have tweeted about TrumpCare the past week. (thread)"
end
