require 'sinatra'
require 'sequel'
require 'json'
require 'logger'
require 'nokogiri'
require 'yaml'
require 'uri'
require 'open-uri'

CONFIG = YAML::load_file('config.yml')

class Array
  def uniq_by
    hash, array = {}, []
    each { |i| hash[yield(i)] ||= (array << i) }
    array
  end
end

class ErisWeb < Sinatra::Base
  set :static, true
  set :root, File.dirname(__FILE__)

  helpers {
    def prep_feed_item(p)
      p['date_string'] = DateTime.parse(p['date']).strftime("%b %d %I:%M %p")
      if p['image_file']
        image_path = "/feed-images/#{p['item_id']}/#{p['image_file']}"
        p['image_tag'] = %Q[<a href="#{p['item_href']}"><img class="feed-item-image" src="#{image_path}"/></a>] 
      else
        p['image_tag'] = ''
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

    def apps 
      a = CONFIG['apps'].keys
    end

    def app_config
      a = CONFIG['apps'][@app]
      s = request.env['SERVER_NAME'] 
      if @app == 'music' && s !~ /bostonmusichub/
        a['page']['title'] = 'boston music'
        a['org']['name'] = 'bostonstuff.org'
        a['org']['href'] = 'http://bostonstuff.org'
      end
      a
    end

    def tweet_service_url
      url = CONFIG['services']['twitter'] + "/application/#{@app_id}/tweets"
    end

    def tweets(params={})
      query = params.empty? ? "" : 
        ("?" + URI.escape(params.select {|k,v| v != 'undefined'}.map {|k,v| "#{k}=#{URI.escape v}"}.join("&")))
      url = tweet_service_url + query
      res = JSON.parse(open(url).read).uniq_by {|x| x['tweet_id']}
      res
    end

    def feeds_service_url
      url = CONFIG['services']['feeds'] + "/application/#{@app_id}/items"
    end

    def feed_items(params={})
      query = params.empty? ? "" : 
        ("?" + URI.escape(params.select {|k,v| v != 'undefined'}.map {|k,v| "#{k}=#{URI.escape v}"}.join("&")))
      url = feeds_service_url + query
      res = JSON.parse open(url).read
      # filter out items with little or no text content
      res = res.select {|item| item['summary'].length > 200}
      res
    end
  }

  MIN_CONTENT_LENGTH = 100
  get('/') {
    erb :home
  }

  get('/:app') {|app|
    @app = app
    @app_id = app_config['app_id']
    @tweets = tweets.map {|t| prep_tweet t}
    @feed_items = feed_items.map {|t| prep_feed_item t}
    erb :page
  }

  get('/:app/tweets') {|app|
    @app = app
    @app_id = app_config['app_id']
    resp = tweets(from_time: params[:from_time]).map {|x| prep_tweet x}.to_json
  }

  get('/:app/feed_items') {|app|
    @app = app
    @app_id = app_config['app_id']
    resp = feed_items(from_time: params[:from_time]).map {|x| prep_feed_item x}.to_json
  }

  run! if app_file == $0
end
