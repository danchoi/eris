require 'db'
puts "Processing images"
DB[:images].each {|x|
  dir = "img/#{x[:blog_post_id]}"
  path = "#{dir}/#{x[:filename]}"
  unless File.exist?(path)
    `mkdir -p #{dir}`
    `wget -O #{path} '#{x[:src]}'`
    /(?<width>\d+)x(?<height>\d+) / =~ `identify #{path}`
    puts "Image dimensions: #{width}x#{height}"
  end
}
