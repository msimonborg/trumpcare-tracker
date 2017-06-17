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

    attr_reader :screen_name, :first_tweet_block

    def initialize(screen_name, &first_tweet_block)
      @screen_name       = screen_name
      @first_tweet_block = first_tweet_block
      tweet_bot_task
    end

    def tweet_bot_task
      namespace(:tracker) do
        namespace(:tweet_bot) do
          desc 'Audit Democrats Trumpcare tweet activity and post a thread of updates'
          task(:democrats) do
            tweet_bot(:democrats)
          end

          desc 'Audit Republicans Trumpcare tweet activity and post a thread of updates'
          task(:republicans) do
            tweet_bot(:republicans)
          end
        end
      end
    end

    def tweet_bot(caucus)
      tracker = TrumpcareTracker.new('TrumpCareTracker', screen_name)
      tweet = Twitter::Tweet.new(id: nil)
      first_tweet = tracker.client.update(first_tweet_block.call) if block_given?
      send(caucus).each_with_index do |rep, i|
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