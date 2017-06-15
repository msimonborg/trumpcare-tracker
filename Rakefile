# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'csv'
require 'pyr'
require 'trumpcare_tracker'

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Output a report of Senate Democrats Trumpcare tweets'
task :export do
  reps = PYR.reps do |r|
    r.party = 'democrat'
    r.chamber = 'upper'
  end

  csv_report = CSV.generate do |csv|
    csv << %w[
        senator
        user_name
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
    file.write csv_report
  end
end

desc 'Audit and tweet results'
task :tweet do
  reps = PYR.reps do |r|
    r.party   = 'democrat'
    r.chamber = 'upper'
  end

  audit_tweets(reps) do |tracker, rep|
    tracker.to_tweet
    tracker.client.update(
      "#{rep.official_full}\n"\
      "#{rep.office_locations.map { |off| "#{off.city} - #{off.phone}" }.join("\n")}"
    )
  end
end

def audit_tweets(reps)
  reps.objects.each_with_index do |rep, i|
    puts "Sending requests to Twitter API for #{rep.official_full}"
    tracker = TrumpcareTracker.new(rep.twitter)
    next if tracker.user.screen_name.downcase != rep.twitter.downcase
    tracker.audit
    yield(tracker, rep) if block_given?
    puts "#{i + 1} down. Pausing for 45 seconds to avoid hitting API rate limit."
    sleep(45)
  end
end