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
  # $ rake tracker:export:senate_democrats
  # $ rake tracker:export:house_democrats
  # $ rake tracker:export:senate_republicans
  # $ rake tracker:export:house_republicans
  # $ rake tracker:export:all
  #
  # $ rake tracker:homepage_scraper:senate_democrats
  # $ rake tracker:homepage_scraper:house_democrats
  # $ rake tracker:homepage_scraper:senate_republicans
  # $ rake tracker:homepage_scraper:house_republicans
  # $ rake tracker:homepage_scraper:all
class Reporters < RakeTask
    def initialize
      export_task
      homepage_scraper_task
    end

    def export_task
      namespace(:tracker) do
        namespace(:export) do
          desc 'Output a report of Senate Democrats Trumpcare tweets'
          task(:senate_democrats) { export(:senate_democrats) }

          desc 'Output a report of House Democrats Trumpcare tweets'
          task(:house_democrats) { export(:house_democrats) }

          desc 'Output a report of Senate Republicans Trumpcare tweets'
          task(:senate_republicans) { export(:senate_republicans) }

          desc 'Output a report of House Republicans Trumpcare tweets'
          task(:house_republicans) { export(:house_republicans) }

          all_tasks
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
      namespace(:tracker) do
        desc 'Search Senators\' official homepage for TrumpCare and Russia Mentions'
        namespace(:homepage_scraper) do
          desc 'Search Senate Democrat\'s homepages'
          task(:senate_democrats) { homepage_scraper(:senate_democrats) }

          desc 'Search House Democrat\'s homepages'
          task(:house_democrats) { homepage_scraper(:house_democrats) }

          desc 'Search Senate Republican\'s homepages'
          task(:senate_republicans) { homepage_scraper(:senate_republicans) }

          desc 'Search House Republican\'s homepages'
          task(:house_republicans) { homepage_scraper(:house_republicans) }

          all_tasks
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

    def all_tasks
      desc 'Run for each caucus'
      task(all: [:senate_democrats, :house_democrats, :senate_republicans, :house_republicans])
    end
  end
end