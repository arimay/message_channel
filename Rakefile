require "bundler/gem_helper"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

class Bundler::GemHelper

  def git_archive( dir = "../zip" )
    FileUtils.mkdir_p  dir
    dest_path  =  File.join(dir, "#{name}-#{version}.zip")
    cmnd  =  "git archive --format zip --prefix=#{name}/ HEAD > #{dest_path}"

    out, code = sh_with_status( cmnd )
    raise "Couldn't archive gem,"  unless  code == 0

    Bundler.ui.confirm "#{name} #{version} archived to #{dest_path}."
  end

  def git_push
    ver  =  version.to_s

    cmnd  =  "git push origin  #{ver} "
    out, code = sh_with_status( cmnd )
    raise "Couldn't git push origin."  unless  code == 0

    cmnd  =  "git push "
    out, code = sh_with_status( cmnd )
    raise "Couldn't git push."         unless  code == 0

    Bundler.ui.confirm "Git Push #{ver}."
  end

  def update_version( new_version )
    version_filename  =  %x[ find . -type f -name "version.rb" | grep -v vendor | head -1 ].chomp
    version_pathname  =  File.expand_path( version_filename )
    lines  =  File.open( version_pathname ).read
    lines  =  lines.gsub( /VERSION\s*=\s*\"\d+\.\d+\.\d+\"/, "VERSION = \"#{new_version}\"" )
    File.open( version_pathname, "w" ) do |file|
      file.write( lines )
    end

    cmnd  =  "git add  #{version_pathname} "
    out, code = sh_with_status( cmnd )
    raise "Couldn't git add,"  unless  code == 0

    cmnd  =  "git commit -m  '#{new_version}' "
    out, code = sh_with_status( cmnd )
    raise "Couldn't git commit."  unless  code == 0

    cmnd  =  "git tag        #{new_version} "
    out, code = sh_with_status( cmnd )
    raise "Couldn't git tag."          unless  code == 0

    Bundler.ui.confirm "Update Tags to #{new_version}."
  end

end

Bundler::GemHelper.new(Dir.pwd).instance_eval do

  desc "Archive #{name}-#{version}.zip from repository"
  task 'zip' do
    git_archive
  end

  desc "Git Push"
  task 'push' do
    git_push
  end

  desc "Update Version Tiny"
  task 'tiny' do
    major, minor, tiny  =  version.to_s.split('.')
    new_version  =  [major, minor, tiny.to_i + 1].join('.')
    update_version( new_version )
  end

  desc "Update Version Minor"
  task 'minor' do
    major, minor, tiny  =  version.to_s.split('.')
    new_version  =  [major, minor.to_i + 1, 0].join('.')
    update_version( new_version )
  end

  desc "Update Version Major"
  task 'major' do
    major, minor, tiny  =  version.to_s.split('.')
    new_version  =  [major.to_i + 1, 0, 0].join('.')
    update_version( new_version )
  end

end

