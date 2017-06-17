# frozen_string_literal: true

require 'trumpcare_tracker/version'
require 'twitter'

# Track the Twitter mentions of Trumpcare by Democratic US Senators
class TrumpcareTracker
  CONSUMER_KEY        = ENV['TCT_CONSUMER_KEY']
  CONSUMER_SECRET     = ENV['TCT_CONSUMER_SECRET']
  ACCESS_TOKEN        = ENV['TCT_ACCESS_TOKEN']
  ACCESS_TOKEN_SECRET = ENV['TCT_ACCESS_TOKEN_SECRET']

  attr_reader :user, :screen_name, :alt_screen_name

  def self.ratio(numerator, denominator)
    return 0.0 if denominator.zero?
    (numerator / denominator.to_f).round(4)
  end

  def self.percentage(numerator, denominator)
    (ratio(numerator, denominator) * 100).round(2)
  end

  def self.trumpcare_keyword_regex
    /(ahca|trumpcare|healthcare|health|care|drug|medication|prescription|vaccine|obamacare|cbo|premiums|insurance|deductibles|aca|o-care|a.h.c.a|a.c.a)/
  end

  def self.russia_keyword_regex
    /(russia|comey|sessions|mueller|fbi|flynn|obstruction of justice|collusion|putin|kremlin)/
  end

  def initialize(user, screen_name, alt_screen_name = nil)
    @user            = user
    @screen_name     = client.user screen_name
    @alt_screen_name = client.user alt_screen_name if alt_screen_name
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
    @_timeline ||= (fetch_timeline(screen_name) + fetch_timeline(alt_screen_name))
  end

  # Make two cursored API calls to fetch the 400 most recent tweets
  def fetch_timeline(screen_name)
    return [] unless screen_name
    timeline = client.user_timeline(screen_name, exclude_replies: true, count: 200)
    timeline + client.user_timeline(
      screen_name,
      exclude_replies: true,
      max_id: timeline.last.id - 1,
      count: 200
    )
  end

  # Collect a user's tweets within the last 7 days
  def recent_tweets
    @_recent_tweets ||= timeline.each_with_object([]) do |tweet, memo|
      age_of_tweet_in_days = (Time.now.to_date - tweet.created_at.to_date).to_i
      memo << tweet if age_of_tweet_in_days <= 7
    end
  end

  def reduce_by_keywords(regex)
    recent_tweets.each_with_object([]) do |tweet, memo|
      tweet_with_full_text = client.status(tweet.id, tweet_mode: 'extended')
      memo << tweet if tweet_match?(tweet_with_full_text, regex)
    end
  end

  def tweet_match?(tweet, regex)
    full_text = tweet.attrs[:full_text]
    if full_text.downcase.match?(regex)
      true
    elsif tweet.quoted_tweet?
      quoted_tweet = client.status(tweet.quoted_tweet.id, tweet_mode: 'extended')
      tweet_match?(quoted_tweet, regex)
    else
      false
    end
  end

  def trumpcare_tweets
    @_trumpcare_tweets ||= reduce_by_keywords(self.class.trumpcare_keyword_regex)
  end

  def russia_tweets
    @_russia_tweets ||= reduce_by_keywords(self.class.russia_keyword_regex)
  end

  def audit
    puts to_s
  end

  def to_s
    @_to_s ||= "@#{screen_name.screen_name}'s last 7 days\n#{recent_tweets_count} tweets\n"\
      "#{trumpcare_tweets_count} TrumpCare - #{trumpcare_tweets_percentage}%\n"\
      "#{russia_tweets_count} Russia - #{russia_tweets_percentage}%\n"\
      "#{trumpcare_to_russia_tweets_ratio} TrumpCare tweets for every Russia tweet"
  end

  def recent_tweets_count
    @_recent_tweets_count ||= recent_tweets.count
  end

  def trumpcare_tweets_count
    @_trumpcare_tweets_count ||= trumpcare_tweets.count
  end

  def russia_tweets_count
    @_russia_tweets_count ||= russia_tweets.count
  end

  def trumpcare_tweets_percentage
    self.class.percentage(trumpcare_tweets.count, recent_tweets.count)
  end

  def russia_tweets_percentage
    self.class.percentage(russia_tweets.count, recent_tweets.count)
  end

  def trumpcare_to_russia_tweets_ratio
    self.class.ratio(trumpcare_tweets.count, russia_tweets.count)
  end

  def to_h
    {
      senator: user,
      official_user_name: screen_name.screen_name,
      alt_user_name: alt_screen_name_screen_name,
      tweets_in_last_seven_days: recent_tweets.count,
      trumpcare_tweet_count: trumpcare_tweets.count,
      tct_percentage: trumpcare_tweets_percentage,
      russia_tweet_count: russia_tweets.count,
      rt_percentage: russia_tweets_percentage,
      tct_to_rt_ratio: trumpcare_to_russia_tweets_ratio,
      trumpcare_tweet_urls: trumpcare_tweets.map { |tweet| tweet.uri.to_s },
      russia_tweet_urls: russia_tweets.map { |tweet| tweet.uri.to_s }
    }
  end

  def alt_screen_name_screen_name
    return '' unless alt_screen_name
    alt_screen_name.screen_name
  end

  def to_tweet(options = {})
    client.update(".#{self}", options)
  end
end
