require 'HTTParty'
require 'Nokogiri'
require 'JSON'

def parse_page(url:)
  page = HTTParty.get(url)
  Nokogiri::HTML(page)
end

def drips_for(topic:)
  topic_url = "https://www.dailydrip.com/topics/#{topic}"
  puts "Gathering topic urls from #{topic_url}"

  parse_page(url: topic_url).css('div.drips.topics').css('a').collect do |link|
    'https://www.dailydrip.com' + link.attributes['href'].value
  end
end

def media_script_for(drip:)
  parse_page(url: drip).css('script').find do |script|
    script.children.to_s.include? 'DailyDrip.Drip.show'
  end
end

def media_for(drip:)
  tag = media_script_for(drip: drip).children.to_s.strip
  tag.slice! 'DailyDrip.Drip.show('
  tag.chomp!(')')

  json = JSON.parse(tag)
  json['video']['url']
end

def download_media_for(drip:, location:, topic:)
  media = media_for(drip: drip)
  system "wget -c #{media} -P #{location}/#{topic}"
end

###################################################
###                 CLI Starts                  ###
###################################################

puts 'Which topic do you want to download?'
topic = gets.chomp

puts 'Where do you want to save the videos?'
location = gets.chomp

drips = drips_for(topic: topic)

drips.each_with_index do |drip, index|
  puts "Downloading #{index + 1} of #{drips.size}"
  puts drip

  download_media_for(drip: drip, location: location, topic: topic)
end

puts 'Done!!'
