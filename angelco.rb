# https://angel.co/syndicates?list_name=leaderboard&page=2&list_name=leaderboard

require 'open-uri'
require 'nokogiri'

module Angelco

  class Investor
    def initialize( name, typically_invests, backers, backed_by )
      @name, @typically_invests, @backers, @backed_by = name, typically_invests, backers, backed_by
    end
  end

  def self.get_syndicates()

    syndicates = []

    $n = 69
    $ps = 100

    while( $ps > 35 ) do

      raw_html = open("https://angel.co/syndicates?list_name=leaderboard&page=#{$n}&list_name=leaderboard").read()

      page = Nokogiri::HTML( raw_html )

      $ps = page.css('.item').size

      page.css('.item').each do |item|
        investor_name = item.css('.info').css('.name').css('a').inner_text
        if investor_name.size > 2
          #puts investor_name
          if item.inner_text.include?("Hasn't created a syndicate")
            typically_invests, backers, backed = -1, -1, -1
          else
            typically_invests = item.css('.amount').inner_text.split("\n").last.gsub("$", "").gsub(",", "").to_i
            backers = item.css('.backers').inner_text.split("\n").last.strip.to_i
            backed = item.css('.backed').inner_text.split("\n").last.gsub("$", "").gsub(",", "").to_i
            if backers == 0 
              backers = -1
            end
            if backed == 0
              backed = -1
            end
            if typically_invests == 0
              backed = -1
            end
          end

          i = Investor.new( investor_name, typically_invests, backers, backed )
          syndicates.push( i )
        end
      end

    $n += 1

    end

    return syndicates

  end
end
