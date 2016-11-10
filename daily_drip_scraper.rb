require 'HTTParty'
require 'Nokogiri'
require 'JSON'

def topic_urls_for(index_url:)
  puts "Gathering topic urls from #{index_url}"
  page = HTTParty.get(index_url)
  parsed_page = Nokogiri::HTML(page)

  parsed_page.css('div.drips.topics').css('a').collect do |link|
    'https://www.dailydrip.com' + link.attributes['href'].value
  end
end

def download_url_for(topic_url:)
  page = HTTParty.get(topic_url)
  parse_page = Nokogiri::HTML(page)

  drip_script = parse_page.css('script').select do |script|
    script.children.to_s.include? 'DailyDrip.Drip.show'
  end

  tag = drip_script.first.children.to_s.strip
  tag.slice! 'DailyDrip.Drip.show('
  tag.chomp!(')')

  json = JSON.parse(tag)
  json['video']['url']
end

index_url = 'https://www.dailydrip.com/topics/elixir/'
topic_urls = topic_urls_for(index_url: index_url)

total_size = topic_urls.size
puts "#{total_size} found"

topic_urls.each_with_index do |topic_url, index|
  puts "Downloading #{index + 1} of #{total_size}"
  puts topic_url
  download_url = download_url_for(topic_url: topic_url)
  system "wget -c #{download_url}"
end

puts 'Done!!'
