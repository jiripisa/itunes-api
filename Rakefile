require 'rubygems'
require 'rake/clean'
require 'rake/gempackagetask'

CLEAN.include("pkg")

spec = Gem::Specification.new do |s|
    s.name       = "itunes-api"
    s.version    = "0.5"
    s.author     = "Jiri Pisa"
    s.email      = "jiri.pisa@jetminds.com"
    s.homepage   = "http://jetminds.com"
    s.summary    = "API for your iTunes library."
    s.platform   = Gem::Platform::RUBY
    s.files      = FileList["{lib}/**/*"].exclude("rdoc").to_a
    s.require_path      = "lib"
    s.has_rdoc          = false
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip   = true
end

desc "Installs the gem"
task :installer do
  Dir.chdir"pkg"
  system "gem install itunes-api" 
end

desc "Default rake task"
task :default => [:clean, :package, :installer, :clean]