Gem::Specification.new do |s|
  s.name = 'treeify'
  s.version = '0.04'
  s.summary = 'Simple trees for ActiveRecord using PostgreSQL'
  s.date    = "2014-06-11"
  s.author = 'Devin Austin'
  s.email = 'devin.austin@gmail.com'
  s.homepage = 'http://github.com/dhoss/treeify'
  s.description = 'Simple trees for ActiveRecord'
  s.files = "lib/treeify.rb"
  s.license = "MIT"
  s.homepage = "http://rubygems.org/gems/treeify"
  s.add_runtime_dependency "pg", "0.17.1"
  s.add_runtime_dependency "activerecord", "~> 4.1.6"
  s.add_development_dependency "rspec", "3.1.0"
  s.add_development_dependency "rake", "10.3.2"
  s.add_development_dependency "database_cleaner", "1.3.0"
end
