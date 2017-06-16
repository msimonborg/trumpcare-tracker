# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'csv'
require 'nokogiri'
require 'open-uri'
require 'pyr'
require 'trumpcare_tracker'

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Output a report of Senate Democrats Trumpcare tweets'
task :export do
  csv_tweet_report = CSV.generate do |csv|
    csv << %w[
      senator
      official_user_name
      alt_user_name
      tweets_in_last_seven_days
      trumpcare_tweets
      tct_percentage
      russia_tweets
      rt_percentage
      tct_to_rt_ratio
      trumpcare_tweet_urls
      russia_tweet_urls
    ]
    audit_tweets(reps) { |tracker| csv << tracker.to_h.values }
  end

  File.open('trumpcare_tweet_report.csv', 'w') do |file|
    file.write csv_tweet_report
  end
end

desc 'Search Senators\' official homepage for TrumpCare and Russia Mentions'
task :scrape_homepage do
  csv_homepage_report = CSV.generate do |csv|
    csv << %w[senator url trumpcare_mentions russia_mentions trumpcare_to_russia_ratio]
    reps.each do |rep|
      doc = Nokogiri::HTML(open(rep.url))
      trumpcare_mentions_count = mentions_mapper(doc, TrumpcareTracker.trumpcare_keyword_regex).count
      russia_mentions_count = mentions_mapper(doc, TrumpcareTracker.russia_keyword_regex).count
      csv << [
        rep.official_full,
        rep.url,
        trumpcare_mentions_count,
        russia_mentions_count,
        TrumpcareTracker.ratio(trumpcare_mentions_count, russia_mentions_count)
      ]
      puts "Scraped #{rep.official_full}'s homepage"
    end
  end

  File.open('trumpcare_homepage_report.csv', 'w') do |file|
    file.write csv_homepage_report
  end
end

def mentions_mapper(doc, regex)
  doc.text.split("\n").select { |string| string.downcase.match?(regex) }
end

desc 'Audit and tweet results'
task :tweet do
  audit_tweets(reps) do |tracker, rep|
    tracker.to_tweet
    tracker.client.update(
      "#{rep.official_full}\n"\
      "#{rep.office_locations.map { |off| "#{off.city} - #{off.phone}" }.join("\n")}"
    )
  end
end

def reps
  democrats = PYR.reps do |r|
    r.democrat = true
    r.chamber  = 'upper'
  end

  independents = PYR.reps do |r|
    r.independent = true
    r.chamber     = 'upper'
  end

  democrats.objects.to_a + independents.objects.to_a
end

def handles
  @_handles ||= CSV.read('twitter_handles.csv', headers: true)
end

def audit_rep(i, rep, &block)
  puts "Sending requests to Twitter API for #{rep.official_full}"
  alt_screen_name = handles.detect do |handle|
    handle['official'].downcase.strip == rep.twitter.downcase.strip
  end['personal/campaign']
  tracker = TrumpcareTracker.new(rep.official_full, rep.twitter, alt_screen_name)
  tracker.audit
  block.call(tracker, rep) if block_given?
  puts "#{i + 1} down. Pausing for 45 seconds to avoid hitting API rate limit."
  sleep(45)
rescue Twitter::Error::TooManyRequests
  puts 'Rate limit exceeded, waiting 2 minutes'
  sleep(300)
  audit_rep(i, rep, &block)
rescue Twitter::Error => e
  puts e.message
  audit_rep(i, rep, &block)
end

def audit_tweets(reps, &block)
  reps.each_with_index do |rep, i|
    next if rep.twitter.nil?
    audit_rep(i, rep, &block)
  end
end
