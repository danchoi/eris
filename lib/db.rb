require 'sequel'
require 'yaml'
CONFIG = YAML::load_file("config.yml")
DB = Sequel.connect CONFIG['database']
