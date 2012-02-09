require 'sinatra'
require 'sequel'
require 'json'
require 'logger'
require 'nokogiri'
require 'yaml'
require 'uri'
require 'open-uri'

CONFIG = YAML::load_file('config.yml')
puts CONFIG.inspect

class ErisWeb < Sinatra::Base
  set :static, true
  set :root, File.dirname(__FILE__)

  helpers {
    def prep(p)
      p[:date_string] = p[:date].strftime("%b %d %I:%M %p")
      if p[:content] 
        # strip Github dates because they are redundant
        p[:content] = p[:content].sub(/\w+ \d+, \d{4}/, '')
      end
      if p.has_key?(:img)
        p[:imgtag] = p[:img] ? %Q[<a href="#{p[:item_href]}"><img class="feed-item-image" src="#{p[:img]}"/></a>] : nil
      end
      p
    end

    def prep_tweet t
      puts t.inspect
      t[:user_screen_name]
      tweet_href = "<a href='http://twitter.com/#{t[:user_screen_name]}/status/#{t[:id]}'>#{t[:created_at].strftime("%b %d %I:%M %p")}</a>"
      t[:user_screen_name].gsub!(/.*/, '<a href="http://twitter.com/\0">\0</a>')
      new = t[:text].gsub(/http:[\S,\]\)\.\;]+/, '<a href="\0">\0</a>')
      new = new.gsub(/@(\w+)/, '<a href="http://twitter.com/\1">@\1</a>')
      t[:date_string] = tweet_href
      t[:text] = new 
      t
    end

    def app_config(app)
      CONFIG['apps'][app]
    end

    def app_id(app)
      app_config(app)['app_id']
    end

    def tweets
      url = CONFIG['services']['twitter'] + "/application/#{@app_id}/tweets"
      puts "Calling service: #{url}"
      JSON.parse open(url).read
    end

    def feed_items
      url = CONFIG['services']['feeds'] + "/application/#{@app_id}/items"
      puts "Calling service: #{url}"
      JSON.parse open(url).read
    end
  }

  MIN_CONTENT_LENGTH = 100
  get('/') {
    CONFIG.to_yaml
  }
  get('/:app') {|app|
    @app_id = app_id(app)
    @tweets = tweets.map {|t| prep_tweet t}
    @feed_items = feed_items.map {|t| prep t}
    erb :index 
  }

  get('/:app/feed_items') {|app|
    next "OK"
    @blog_posts = DB[:blog_posts].
      order(:inserted_at.desc).
      filter("length(coalesce(summary, '')) > #{MIN_CONTENT_LENGTH} and date > ?", params[:from_time]).
      map {|p| prep p}
    @blog_posts.to_json
  }
  get('/:app/tweets') {|app|
    next "OK"
    ds = DB[:tweets].order(:inserted_at.desc).filter("created_at > ?", params[:from_time])
    @tweets = ds.map {|p| prep_tweet p}
    @tweets.to_json
  }

  run! if app_file == $0
end
