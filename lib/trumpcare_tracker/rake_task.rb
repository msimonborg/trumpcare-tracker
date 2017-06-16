# frozen_string_literal: true

require 'csv'
require 'pyr'
require 'trumpcare_tracker'

class TrumpcareTracker
  # Base rake task class
  class RakeTask < Rake::TaskLib
    module Methods
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
        @_handles ||= CSV.read('trumpcare_tracker/lib/twitter_handles.csv', headers: true)
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
end