Gem::Specification.new do |s|
  s.name = 'treeify'
  s.version = '0.03'
  s.summary = 'Simple trees for ActiveRecord using PostgreSQL'
  s.date    = "2014-06-11"
  s.author = 'Devin Austin'
  s.email = 'devin.austin@gmail.com'
  s.homepage = 'http://github.com/dhoss/treeify'
  s.description = 'Simple trees for ActiveRecord'
  s.files = "lib/treeify.rb"
  s.license = "MIT"
  s.homepage = "http://rubygems.org/gems/treeify"
  s.add_runtime_dependency "pg"
  s.add_runtime_dependency "activerecord", "~> 4.1.1"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "database_cleaner"
end
