$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'bundler'
Bundler.setup
require 'rspec'
require 'fabrication'
require 'database_cleaner'


require 'mm_sortable_item'

MongoMapper.database = 'mm_sortable_item_spec'

class SortableHelper
  include MongoMapper::Document
  plugin MongoMapper::Plugins::SortableItem

  key :name, String
  key :list_scope_id, Integer
end

SortableHelper.collection.remove

RSpec.configure do |config|
  config.mock_with :rspec
  
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
    DatabaseCleaner.clean
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end