# aggregates blogs

require 'nokogiri'
require 'feed_yamlizer'
require 'db'

feeds = CONFIG['feeds']
feeds.each {|f|

  cmd = "curl -Ls '#{f}' | feed2yaml"
  puts cmd
  feedyml = `#{cmd}`
  x = YAML::load feedyml

  blog = x[:meta]
  params = { html_url:blog[:link], title:blog[:title].strip, feed_url:f }
  if DB[:blogs].first(feed_url:params[:feed_url])
    print '.'
  else
    DB[:blogs].insert params
  end
  x[:items].each { |i| 
    # Reject if no pub_date
    unless i[:pub_date]
      puts "No pub date! Rejecting"
      next
    end
    html = i[:content][:html]
    n = nil 
    content = if html 
      n = Nokogiri::HTML(html).xpath('/')
      if n
        words = n.inner_text[0,355].split(/\s/)
        words[0..-2].join(' ') + '...' 
      end
    end

    if content
      content.force_encoding("UTF-8")
    end

    e = { 
      blog: x[:meta][:title],
      feed_url: f,
      blog_post_href: i[:link],
      title: i[:title],
      author: i[:author],
      date: i[:pub_date],
      summary: content
    }
    if DB[:blog_posts].first blog_post_href: e[:blog_post_href]
      $stderr.print '.'
    else
      puts "Inserting #{e[:blog]} => #{e[:title]}"
      blog_post_id = DB[:blog_posts].insert e

      # Insert images into DB 
      # Save in file system and process with rake images
      if n
        n.search("img").select {|img| 
          img[:height] != '1' &&
          img[:width] != '1' &&
          img[:alt] !~ /^Add to/ && 
          !DB[:images].first(src:img[:src]) 
        }.each {|img|
          filename = img[:src][/[^\/?#]+.(jpg|jpeg|git|png)/i,0]
          next unless filename
          params = {
            blog_post_id:blog_post_id,
            src:img[:src],
            filename:filename
          }
          DB[:images].insert params
        }
      end
    end
  }    
}
