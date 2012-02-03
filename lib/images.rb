require 'db'
puts "Processing images"
DB[:images].order(:inserted_at.asc).each {|x|
  dir = "public/img/#{x[:blog_post_id]}"
  path = "#{dir}/#{x[:filename]}"
  unless File.exist?(path)
    `mkdir -p #{dir}`
    `wget -O #{path} '#{x[:src]}'`
    `convert #{path} -resize '200x150>' #{path}.tmp`
    `mv #{path}.tmp #{path}`
    /(?<width>\d+)x(?<height>\d+) / =~ `identify #{path}`
    puts "Image dimensions: #{width}x#{height}"
    DB[:images].filter(src:x[:src]).update(width:width, height:height)
  end
}
DB[:images].all.group_by {|x| x[:blog_post_id]}.each {|k,v|
  featured = v.first 
  if featured && DB[:blog_posts].first(blog_post_id:featured[:blog_post_id])[:img].nil?
    path = "/img/#{featured[:blog_post_id]}/#{featured[:filename]}"
    DB[:blog_posts].filter(blog_post_id:featured[:blog_post_id]).update(img:path)
  end
}
