$:.push File.expand_path("../lib", __FILE__)
require 'send_grid/version'

Gem::Specification.new do |s|
  s.name = "sendgrid"
  s.version = SendGrid::VERSION
  s.authors = ["Stephen Blankenship", "Marc Tremblay", "Bob Burbach"]
  s.date = "2013-05-15"
  s.description = "This gem allows simple integration between ActionMailer and SendGrid. \n                         SendGrid is an email deliverability API that is affordable and has lots of bells and whistles."
  s.email = "stephenrb@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/send_grid.rb",
    "sendgrid.gemspec",
    "test/sendgrid_test.rb",
    "test/test_helper.rb"
  ]
  s.homepage = "https://github.com/stephenb/sendgrid"
  s.require_paths = ["lib"]
  s.summary = "A gem that allows simple integration of ActionMailer with SendGrid (http://sendgrid.com)"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency 'rails', '>= 3.0'
  s.add_development_dependency 'shoulda', '>= 0'
end

