require 'httparty'
require 'nokogiri'
require 'byebug'
require 'sqlite3'
require 'active_record'
require 'chronic'

require_relative './models/channel'
require_relative './models/video'

#---------------------#
# Load Configurations #
#---------------------#

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  # byebug
  YAML.load(File.read(db_configuration_file))
end

#---------------------#
# Database Connection #
#---------------------#

ActiveRecord::Base.establish_connection(db_configuration[ "development" ])

#-------------------#
# Development Seeds #
#-------------------#

# byebug

[
  "https://www.youtube.com/channel/UC_7aK9PpYTqt08ERh1MewlQ",
  "https://www.youtube.com/channel/UCbgBDBrwsikmtoLqtpc59Bw",
  "https://www.youtube.com/channel/UCYO_jab_esuFRV4b17AJtAw",
  "https://www.youtube.com/channel/UCdcemy56JtVTrsFIOoqvV8g",
  "https://www.youtube.com/channel/UCtM5z2gkrGRuWd0JQMx76qA",
  "https://www.youtube.com/channel/UCq6aw03lNILzV96UvEAASfQ",
  "https://www.youtube.com/channel/UCQ4FyiI_1mWI2AtLS5ChdPQ",
  "https://www.youtube.com/channel/UCkK9UDm_ZNrq_rIXCz3xCGA",
  "https://www.youtube.com/channel/UCEOXxzW2vU0P-0THehuIIeg",
  "https://www.youtube.com/channel/UC9z7EZAbkphEMg0SP7rw44A",
  "https://www.youtube.com/channel/UC2C_jShtL725hvbm1arSV9w",
  "https://www.youtube.com/channel/UCKOvOaJv4GK-oDqx-sj7VVg",
  "https://www.youtube.com/channel/UC0e3QhIYukixgh5VVpKHH9Q",
  "https://www.youtube.com/channel/UCUQo7nzH1sXVpzL92VesANw",
  "https://www.youtube.com/channel/UCJ0-OtVpF0wOKEqT2Z1HEtA",
  "https://www.youtube.com/channel/UCMLgHbpJ8qYqj3CkdbvC0Ww",
  "https://www.youtube.com/channel/UCdGHXaYCp8Gg2w2pXWpZt5A",
  "https://www.youtube.com/channel/UCoLUji8TYrgDy74_iiazvYA",
  "https://www.youtube.com/channel/UCP4nS6ag1-E6TzlQvaWfiZg",
  "https://www.youtube.com/channel/UCsXVk37bltHxD1rDPwtNM8Q",
  "https://www.youtube.com/channel/UCFk__1iexL3T5gvGcMpeHNA",
  "https://www.youtube.com/channel/UCxQbYGpbdrh-b2ND-AfIybg",
  "https://www.youtube.com/channel/UCyFjeoG9X83dVWHKqXCKwHg",
  "https://www.youtube.com/channel/UCUHW94eEFW7hkUMVaZz4eDg",
  "https://www.youtube.com/channel/UCS_H_4AmsqC705DObesZIIg",
  "https://www.youtube.com/channel/UCFhXFikryT4aFcLkLw2LBLA",
  "https://www.youtube.com/channel/UC7DdEm33SyaTDtWYGO2CwdA",
  "https://www.youtube.com/channel/UCvlj0IzjSnNoduQF0l3VGng",
  "https://www.youtube.com/channel/UCEIwxahdLz7bap-VDs9h35A",
  "https://www.youtube.com/channel/UCeeFfhMcJa1kjtfZAGskOCA",
  "https://www.youtube.com/channel/UC5I2hjZYiW9gZPVkvzM8_Cw",
  "https://www.youtube.com/channel/UCy0tKL1T7wFoYcxCe0xjN6Q",
  "https://www.youtube.com/channel/UCBa659QWEk1AI4Tg--mrJ2A",
  "https://www.youtube.com/channel/UCP2-S6-M9ZvlY8t7cRn4O6A",
  "https://www.youtube.com/channel/UCOGeU-1Fig3rrDjhm9Zs_wg"
].each do |sub|
  chan = Channel.find_or_initialize_by(url: sub)
  if ( chan.new_record? )
    response = HTTParty.get(chan.url + "/videos")
    parsed = Nokogiri::HTML(response.body)
    name = parsed.css("#c4-primary-header-contents a.branded-page-header-title-link").first.text
    puts "Adding channel #{name}"
    chan.update(name: name)
  else
    puts "Found existing channel #{chan.name}"
  end
end

def get_all_videos
  Channel.all.each do |chan|
    puts "Getting videos from #{chan.name}"
    response = HTTParty.get(chan.url + "/videos")
    parsed = Nokogiri::HTML(response.body)
    video_count = parsed.css("#channels-browse-content-grid > li").count
    current_video = 0
    parsed.css("#channels-browse-content-grid > li").each do |video|
      title_link = video.css(".yt-lockup-title > .yt-uix-sessionlink").first
      name = title_link.text
      link = title_link.attributes["href"].value.match(/v=([^&]+)/)[1]
      duration = video.css(".yt-lockup-thumbnail span.video-time > span").first.text
      vid = Video.find_or_initialize_by(name: name, link: link, duration: duration, channel: chan)
      if vid.new_record?
        vid_response = HTTParty.get("https://www.youtube.com/watch?v=#{vid.link}")
        vid_parsed = Nokogiri::HTML(vid_response.body)
        date = Chronic.parse(vid_parsed.css("strong.watch-time-text").text)
        vid.update(upload_date: date, watched: false)
        puts "Found new Video \"#{vid.name}\" from #{chan.name}"
      end
      current_video += 1
      puts "Video #{current_video}/#{video_count}"
    end
  end
end


get_all_videos
puts "#{Channel.count} channels"
puts "#{Video.count} videos"
