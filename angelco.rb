# https://angel.co/syndicates?list_name=leaderboard&page=2&list_name=leaderboard

require 'open-uri'
require 'nokogiri'

module Angelco

  class Investor

    attr_accessor :name, :link, :typically_invests, :backers, :backed_by

    def initialize( name, link, typically_invests, backers, backed_by )

      @name, @link, @typically_invests, @backers, @backed_by = name, link, typically_invests, backers, backed_by

      @tags, @portfolio, @numbers, @texts = [], [], { :references => 0, :followers => 0, :following => 0 }, {}

    end

    def update_info()

      puts self.name
      puts @link
      raw_html = open( @link ).read()

      page = Nokogiri::HTML( raw_html )

      page.css('.tags').css('.tag').each do |t|
        @tags.push( t.css('a').inner_text )
      end

      page.css('.featured').css('.card').each do |card|
        anchor = card.css('.name').css('a')
        card_name = anchor.inner_text
        card_link = anchor.attr('href').to_s
        card_role = card.css('.role').inner_text

        card_h = { :name => card_name, :link => card_link, :role => card_role }
        @portfolio.push( card_h )
      end
      puts
      page.css('.statistic').each do |section|
        if section.inner_text.include?('References')
          @numbers[:references] = section.css('strong').inner_text.to_i
        end
        if section.inner_text.include?('Followers')
          @numbers[:followers] = section.css('strong').inner_text.to_i
        end
        if section.inner_text.include?('Following')
          @numbers[:following] = section.css('strong').inner_text.to_i
        end
      end

      page.css('.profile_section').each do |section|
        title = section.css('.section_header').inner_text
        if title.include?("What I Do")
          @texts.store(:what_i_do, section.css('.content').inner_text )
        end
        if title.include?("What I'm Looking For")
          @texts.store(:what_im_looking_for, section.css('.content').inner_text )
        end
      end


    end
  end

  def self.get_syndicates()

    syndicates = []

    $n = 1
    $ps = 100

    while( $ps > 35 ) do

      raw_html = open("https://angel.co/syndicates?list_name=leaderboard&page=#{$n}&list_name=leaderboard").read()

      page = Nokogiri::HTML( raw_html )

      $ps = page.css('.item').size

      page.css('.item').each do |item|
        investor_anchor = item.css('.info').css('.name').css('a')
        investor_name = investor_anchor.inner_text
        if investor_name.size > 2
          investor_link = investor_anchor.attr('href').to_s
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

          i = Investor.new( investor_name, investor_link, typically_invests, backers, backed )
          i.update_info()
          syndicates.push( i )

        end
      end

    $n += 1

    end

    return syndicates

  end
end
