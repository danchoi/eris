require 'sinatra'
require 'sequel'
require 'json'
require 'logger'
require 'nokogiri'
require 'yaml'
require 'uri'
require 'open-uri'

CONFIG = YAML::load_file('config.yml')

class ErisWeb < Sinatra::Base
  set :static, true
  set :root, File.dirname(__FILE__)

  helpers {
    def prep(p)
      p['date_string'] = DateTime.parse(p['date']).strftime("%b %d %I:%M %p")
      if p['image_file']
        p['imgtag'] = %Q[<a href="#{p['item_href']}"><img class="feed-item-image" src="#{p['image_file']}"/></a>] 
      end
      p
    end

    def prep_tweet t
      tweet_href = "<a href='http://twitter.com/#{t['screen_name']}/status/#{t['tweet_id']}'>#{DateTime.parse(t['created_at']).strftime("%b %d %I:%M %p")}</a>"
      t['screen_name'].gsub!(/.*/, '<a href="http://twitter.com/\0">\0</a>')
      new = t['text'].gsub(/http:[\S,\]\)\.\;]+/, '<a href="\0">\0</a>')
      new = new.gsub(/@(\w+)/, '<a href="http://twitter.com/\1">@\1</a>')
      t['date_string'] = tweet_href
      t['text'] = new 
      t
    end

    def app_config
      CONFIG['apps'][@app]
    end

    def tweet_service_url
      url = CONFIG['services']['twitter'] + "/application/#{@app_id}/tweets"
    end

    def tweets(params={})
      return [] if params.detect {|k,v| v == 'undefined'}
      query = params.empty? ? "" : 
        ("?" + URI.escape(params.select {|k,v| v != 'undefined'}.map {|k,v| "#{k}=#{URI.escape v}"}.join("&")))
      url = tweet_service_url + query
      puts "Calling service: #{url}"
      res = JSON.parse open(url).read
      puts res
      res
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
    @app = app
    @app_id = app_config['app_id']
    @tweets = tweets.map {|t| prep_tweet t}
    @feed_items = feed_items.map {|t| prep t}
    erb :index 
  }

  get('/:app/tweets') {|app|
    @app = app
    @app_id = app_config['app_id']
    tweets(from_time: params[:from_time])
  }

  get('/:app/feed_items') {|app|
    next "OK"
    @blog_posts = DB[:blog_posts].
      order(:inserted_at.desc).
      filter("length(coalesce(summary, '')) > #{MIN_CONTENT_LENGTH} and date > ?", params[:from_time]).
      map {|p| prep p}
    @blog_posts.to_json
  }

  run! if app_file == $0
end
