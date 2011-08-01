# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mm_sortable_item/version"

Gem::Specification.new do |s|
  s.name        = "mm_sortable_item"
  s.version     = MmSortableItem::VERSION
  s.authors     = ["Matt Wilson"]
  s.email       = ["mhw@hypomodern.com"]
  s.homepage    = "https://github.com/agoragames/mm_sortable_item"
  s.summary     = "Tiny MongoMapper plugin for treating a collection as a list"
  s.description = "Tiny MongoMapper plugin for treating a collection as a list"

  s.rubyforge_project = "mm_sortable_item"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency('mongo_mapper')
  s.add_development_dependency('rspec')
  s.add_development_dependency('fabrication')
  s.add_development_dependency('database_cleaner')
end
