require 'rake'
require 'bundler'
require 'yaml'

$:.unshift 'lib'

def ttask name
  task name do 
    puts "Started #{name} at #{Time.now}"
    require name.to_s
    puts "Finished #{name} at #{Time.now}"
  end
end

ttask :blogs
ttask :tweets
ttask :images

