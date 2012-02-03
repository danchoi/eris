# aggregates blogs

require 'nokogiri'
require 'feed_yamlizer'
require 'yaml'
require 'sequel'

CONFIG = YAML::load_file("config.yml")
DB = Sequel.connect CONFIG['database']
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
    html = i[:content][:html]
    content = if html 
      n = Nokogiri::HTML(html).at('p')
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
      href: i[:link],
      title: i[:title],
      author: i[:author],
      date: i[:pub_date] || Time.now.localtime,
      summary: content
    }
    if DB[:blog_posts].first href: e[:href]
      $stderr.print '.'
    else
      puts "Inserting #{e[:blog]} => #{e[:title]}"
      DB[:blog_posts].insert e
    end
  }    
}
