# https://angel.co/syndicates?list_name=leaderboard&page=2&list_name=leaderboard

require 'open-uri'
require 'nokogiri'
require 'pp'

module Angelco

  class Investor

    attr_accessor :name, :link, :typically_invests, :backers, :backed_by

    def initialize( name, link, typically_invests, backers, backed_by )

      @name, @link, @typically_invests, @backers, @backed_by = name, link, typically_invests, backers, backed_by

      @tags, @portfolio, @numbers, @texts, @references = [], [], { :references => 0, :followers => 0, :following => 0 }, {}, []

    end

    def to_csv()
      ln, fields = "", [ @name, @link, @typically_invests, @backers, @backed_by, @tags.join('|').gsub(',', ''), @numbers.values.join(',') ]
      portfolio = @portfolio.map { |p| p.values.join(",") }
      portfolio.each do |p|
        open(File.join($DIR, 'portfolio.txt'), 'a') do |f|
          f.puts "#{@name},#{@link},#{p}"
        end
      end
      fields.each do |k|
        ln += k.to_s
        ln += "," if k != fields.last
      end
      ln
    end

    def update_info()

      raw_html = open( @link ).read()

      page = Nokogiri::HTML( raw_html )

      #page.css('.tags').css('.tag').each do |t|
      #  @tags.push( t.css('a').inner_text )
      #end
      page.css('.tags').css('.tag').each do |t|
        @tags.push( t.inner_text )
      end

      page.css('.featured').css('.card').each do |card|
        anchor = card.css('.name').css('a')
        card_name = anchor.inner_text
        card_link = anchor.attr('href').to_s
        card_role = card.css('.role').inner_text

        card_h = { :name => card_name, :link => card_link, :role => card_role }
        @portfolio.push( card_h )
      end
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
          @texts.store(:what_i_do, section.css('.content').inner_text.gsub("\n", " ") )
        end
        if title.include?("What I'm Looking For")
          @texts.store(:what_im_looking_for, section.css('.content').inner_text.gsub("\n", " ") )
        end
      end

      open(File.join($DIR, 'texts.txt'), 'a') do |f|
        @texts.each do |label, text|
          f.puts( "#{@name},#{@link},#{label.to_s},\"#{text}\"" )
        end
      end

      page.css('#profile_references').css('.content').css('.profiles').each do |ref|
        anchor = ref.css('.right').css('.name').css('a')
        ref_name = anchor.inner_text
        ref_link = anchor.attr('href').to_s
        @references.push( { :name => ref_name, :link => ref_link } )
      end

      open(File.join($DIR, 'references.txt'), 'a') do |f|
        @references.each do |ref|
          f.puts "#{@name},#{@link},#{ref[:name]},#{ref[:link]}"
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
          open(File.join($DIR, 'syndicates.txt'), 'a') do |f|
            f.puts( i.to_csv )
          end
          syndicates.push( i )

        end
      end

    $n += 1

    end

    return syndicates

  end
end
