require 'sequel'
require 'yaml'
require 'nokogiri'

config = YAML::load_file 'config.yml'

DB = Sequel.connect config['database']

# https://twitter.com/#!/Sooz/boston-rocks/members

user_fields = %w(
  id 
  name 
  screen_name
  location 
  description 
  profile_image_url 
  url 
  followers_count 
  friends_count
  geo_enabled 
)

# insert users into the database

sources = config['twitter_list']
sources.each {|source|

  # list
  %r{/twitter.com/#!/(?<owner>[\w-]+)/(?<list_slug>[\w-]+)/members} =~ source


  url = if list_slug 
    "https://api.twitter.com/1/lists/members.xml?owner_screen_name=#{owner}&slug=#{list_slug}&skip_status=true"
  else
    # single user
    %r{/twitter.com/#!/(?<owner>[\w-]+)$} =~ source
    "https://api.twitter.com/1/users/lookup.xml?screen_name=#{owner}"
  end

  nc = true
  while nc 
    puts "Cursor: #{nc}"
    target_url = (nc.respond_to?(:inner_text) && nc.inner_text =~ /\d+/) ? (url + "&cursor=#{nc.inner_text}") : url
    cmd = "curl -Ls '#{target_url}'"
    puts cmd
    xml = `#{cmd}`
    doc = Nokogiri::XML(xml)
    users = doc.search("user").each {|user|
      params = user_fields.reduce({}) {|m, field|
        m[field.to_sym] = user.at(field).inner_text
        m
      }
      if DB[:twitter_users].first id:params[:id]
        DB[:twitter_users].filter(id:params[:id]).update params
      else
        puts "Inserting #{params[:name]}"
        DB[:twitter_users].insert params
      end
    }
    nc = doc.at('next_cursor')
  end
}
puts "Finished adding users"

# process each user

twitter_fields = %w( id created_at user_screen_name user_description user_location user_followers_count text retweet_count 
  user_profile_image_url)

DB[:twitter_users].all.each { |user|
  screen_name = user[:name]
  return unless screen_name
  url = "http://api.twitter.com/1/statuses/user_timeline.xml?screen_name=#{screen_name}&include_rts=true&count=80"
  sleep 0.5
  xml = `curl -Ls '#{url}'`
  doc = Nokogiri::XML(xml)
  doc.search("status").each {|status|
    params = twitter_fields.reduce({}) {|m, field|
      path = field.sub("user_", "user/")
      if path == 'created_at'
        date = Time.parse(status.at(path).inner_text).localtime
        m[:created_at] = date
      else
        m[field.to_sym] = status.at(path).inner_text
      end
      m
    }
    
    if DB[:tweets].first(id:params[:id])
      $stderr.print '.'
    else
      puts "Inserting tweet: #{params[:user_screen_name]} => #{params[:text]}"
      DB[:tweets].insert params
    end
  }

}
