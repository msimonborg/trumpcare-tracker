# frozen_string_literal: true

require 'trumpcare_tracker/rake_task'

class TrumpcareTracker
  # Provide a tweet bot that can be run as a rake task
  #
  # require 'trumpcare_tracker/tweet_bot'
  # TrumpcareTracker::TweetBot.new('screen_user_name') do
  #   "Text for optional intro tweet to thread"
  # end
  #
  # $ bundle exec rake tracker:tweet_bot
  class TweetBot < RakeTask
    include RakeTask::Methods

    def initialize(screen_name, &first_tweet_block)
      namespace(:tracker) do
        desc 'Audit Trumpcare tweet activity and post a thread of updates'

        task(:tweet_bot) do
          tracker = TrumpcareTracker.new('TrumpCareTracker', screen_name)
          tweet = Twitter::Tweet.new(id: nil)
          first_tweet = tracker.client.update(first_tweet_block.call) if block_given?
          democrats.each_with_index do |rep, i|
            next if rep.twitter.nil?
            reply_to_tweet = if i.zero?
                               first_tweet
                             else
                               tweet
                             end

            begin
              tweet = post(rep, i, reply_to_tweet)
            rescue Twitter::Error => e
              puts e.message
              puts 'Waiting 5 minutes to see if the issue can be resolved.'
              sleep(300)
              tweet = post(rep, i, reply_to_tweet)
            rescue Twitter::Error => e
              puts e.message
              puts 'Waiting 5 more minutes to try one more time. '\
                'If there\'s another exception I\'ll let it fail'
              sleep(300)
              tweet = post(rep, i, reply_to_tweet)
            end
          end
        end
      end
    end

    def post(rep, index, reply_to_tweet)
      puts "Sending requests to Twitter API for #{rep.official_full}"
      tracker = TrumpcareTracker.new(rep.official_full, rep.twitter)
      tweet = tracker.to_tweet(in_reply_to_status: reply_to_tweet)
      sleep(rand(1..5))
      contacts = "#{rep.official_full}\n"\
                  "#{rep.office_locations.map { |off| "#{off.city} - #{off.phone}" }.join("\n")}"
      while contacts.length > 140
        contacts = contacts.split("\n")[0..-2].join("\n")
      end
      tweet = tracker.client.update(contacts, in_reply_to_status: tweet)
      puts "#{index + 1} down. Pausing for some time to avoid hitting API rate limit."
      sleep(rand(30..60))
      tweet
    end
  end
end