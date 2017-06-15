# frozen_string_literal: true

require 'pyr'
require 'trumpcare_tracker/version'
require 'twitter'

# Track the Twitter mentions of Trumpcare by Democratic US Senators
class TrumpcareTracker
  CONSUMER_KEY        = ENV['TCT_CONSUMER_KEY']
  CONSUMER_SECRET     = ENV['TCT_CONSUMER_SECRET']
  ACCESS_TOKEN        = ENV['TCT_ACCESS_TOKEN']
  ACCESS_TOKEN_SECRET = ENV['TCT_ACCESS_TOKEN_SECRET']

  attr_reader :user

  def initialize(user)
    @user = client.user user
  end

  # Instantiate a Twitter Rest Client with API authorization
  def client
    @_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = CONSUMER_KEY
      config.consumer_secret     = CONSUMER_SECRET
      config.access_token        = ACCESS_TOKEN
      config.access_token_secret = ACCESS_TOKEN_SECRET
    end
  end

  def timeline
    @_timeline ||= client.user_timeline(user, exclude_replies: true, count: 200)
  end

  # Collect a user's tweets within the last 7 days
  def recent_tweets
    timeline.each_with_object([]) do |tweet, memo|
      age_of_tweet_in_days = (Time.now.to_date - tweet.created_at.to_date).to_i
      memo << tweet if age_of_tweet_in_days <= 7
    end
  end

  def search_for_keywords(regex)
    recent_tweets.each_with_object([]) do |tweet, memo|
      full_text = client.status(tweet.id, tweet_mode: 'extended').attrs[:full_text]
      memo << tweet if full_text.downcase.match?(regex)
    end
  end

  def healthcare_tweets
    search_for_keywords(healthcare_keyword_regex)
  end

  def healthcare_keyword_regex
    /(ahca|trumpcare|healthcare|health|care|drug|medication|prescription|vaccine)/
  end

  def russia_tweets
    search_for_keywords(russia_keyword_regex)
  end

  def russia_keyword_regex
    /(russia|comey|sessions|mueller|fbi|flynn|obstruction of justice|collusion)/
  end

  def audit
    recent_tweets_count = recent_tweets.count
    healthcare_tweets_count = healthcare_tweets.count
    russia_tweets_count = russia_tweets.count
    puts user.name
    puts recent_tweets_count
    puts "#{healthcare_tweets_count}, #{percentage(healthcare_tweets_count, recent_tweets_count)}%"
    puts "#{russia_tweets_count}, #{percentage(russia_tweets_count, recent_tweets_count)}%"
    puts "#{ratio(healthcare_tweets_count, russia_tweets_count)}"\
      ' health care tweets for ever Russia tweet.'
  end

  def ratio(numerator, denominator)
    (numerator / denominator.to_f).round(4)
  end

  def percentage(numerator, denominator)
    (ratio(numerator, denominator) * 100).round(2)
  end
end
