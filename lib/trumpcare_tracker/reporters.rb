# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'trumpcare_tracker/rake_task'

class TrumpcareTracker
  # Rake tasks to generate audit reports in CSV format
  #
  # require 'trumpcare_tracker/reporters'
  # TrumpcareTracker::Reporters.new
  #
  # $ bundle exec rake tracker:export
  # $ bundle exec rake tracker:homepage_scraper
  class Reporters < RakeTask
    include RakeTask::Methods

    def initialize
      export_task
      homepage_scraper_task
    end

    def export_task
      namespace :tracker do
        namespace :export do
          desc 'Output a report of Senate Democrats Trumpcare tweets'
          task :democrats do
            export(:democrats)
          end

          desc 'Output a report of Senate Republicans Trumpcare tweets'
          task :republicans do
            export(:republicans)
          end
        end
      end
    end

    def export(caucus)
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
        audit_tweets(send(caucus)) { |tracker| csv << tracker.to_h.values }
      end

      File.open("trumpcare_tweet_report_#{caucus}.csv", 'w') do |file|
        file.write csv_tweet_report
      end
    end



    def homepage_scraper_task
      namespace :tracker do
        desc 'Search Senators\' official homepage for TrumpCare and Russia Mentions'
        namespace :homepage_scraper do
          desc 'Search Democrat\'s homepages'
          task :democrats do
            homepage_scraper(:democrats)
          end

          desc 'Search Republican\'s homepages'
          task :republicans do
            homepage_scraper(:republicans)
          end
        end
      end
    end

    def homepage_scraper(caucus)
      csv_homepage_report = CSV.generate do |csv|
        csv << %w[senator url trumpcare_mentions russia_mentions trumpcare_to_russia_ratio]
        send(caucus).each do |rep|
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

      File.open("trumpcare_homepage_report_#{caucus}.csv", 'w') do |file|
        file.write csv_homepage_report
      end
    end
  end
end