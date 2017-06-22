# frozen_string_literal: true

require 'csv'
require 'pyr'
require 'rake'
require 'rake/tasklib'
require 'trumpcare_tracker'

class TrumpcareTracker
  # Base rake task class
  class RakeTask < Rake::TaskLib
    def democrats(chamber = '')
      chamber = chamber.to_s

      democrats = PYR.reps do |r|
        r.democrat = true
        r.chamber  = chamber unless chamber.empty?
      end

      independents = PYR.reps do |r|
        r.independent = true
        r.chamber     = chamber unless chamber.empty?
      end

      democrats.objects.to_a + independents.objects.to_a
    end

    def senate_democrats
      democrats('upper')
    end

    def house_democrats
      democrats('lower')
    end

    def republicans(chamber = '')
      chamber = chamber.to_s

      republicans = PYR.reps do |r|
        r.republican = true
        r.chamber = chamber unless chamber.empty?
      end

      republicans.objects
    end

    def senate_republicans
      republicans('upper')
    end

    def house_republicans
      republicans('lower')
    end

    def handles
      @_handles ||= CSV.read(File.expand_path('../twitter_handles.csv', __FILE__), headers: true)
    end

    def audit_rep(i, rep, &block)
      puts "Sending requests to Twitter API for #{rep.official_full}"
      rep_handles = handles.detect do |handle|
        handle['official'].downcase.strip == rep.twitter.downcase.strip
      end

      alt_screen_name = if rep_handles
        rep_handles['personal/campaign']
      end

      tracker = TrumpcareTracker.new(rep.official_full, rep.twitter, alt_screen_name)
      start_time = Time.now
      tracker.audit
      duration = (Time.now - start_time).round(2)
      puts tracker.to_s
      block.call(tracker, rep) if block_given?

      puts "#{i + 1} down. Out of #{tracker.timeline.length} tweets checked,\n"\
        "#{tracker.recent_tweets.length} were made in the last 7 days.\n"\
        "The oldest tweet analyzed was created #{tracker.recent_tweets.last&.created_at&.strftime("%H:%M:%S %-m/%-d/%y")}\n"\
        "#{tracker.requests} requests took #{duration} seconds."
    rescue Twitter::Error::TooManyRequests
      puts 'Rate limit exceeded, waiting 5 minutes'
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
    ensure
      `say "beep beep beep beep beep"`
    end

    def mentions_mapper(doc, regex)
      doc.text.split("\n").select { |string| string.downcase.match?(regex) }
    end
  end
end
