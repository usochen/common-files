#!/usr/bin/env ruby

# This file generates the correct .gitignore file for the common files, based on HEAD for your installed
# repo. Just run it, and it will print what should go into the .gitignore files.

# The basic premise for functionality is:
# 1) list all of the top-level directories of the common files in the top-level .gitignore 
# 2) add exceptions for everything in those top-level directories by putting !* in the 
#    .gitignore for each of those directories
# 3) List the specific things that we still want to ignore in each of the subdirectory 
#    .gitignore files

# Sample Command: ruby ~/.common_files/generate_gitignore.rb

require 'rubygems'
require 'grit'
include Grit

exceptions_to_the_exception = { 
  ".emacs.d" => ["semantic.cache", "url", "zz-my-stuff.el"],
  ".common_files" => ["*svn", ".last_checked_date", ".out_of_date_last_notified_date", ".out_of_date_notification_message", "cf.conf", "backups"]
}

def common_files_path
  File.expand_path("~")
end

def common_files_repo
  Repo.new(common_files_path)
end

def find_directories_from_git_tree(tree)
  # this abuses the fact that directories don't have the mime_type function defined
  tree.contents.select {|x| !(x.mime_type rescue nil) }
end 

def directories_in_the_common_files
  find_directories_from_git_tree(common_files_repo.commits.first.tree)
end

def ignore_lines_for_a_directory(git_dir)
  <<-eos
!#{git_dir.name}
!#{git_dir.name}/**
  eos
end

# Disclaimer
def disclaimer
  <<-eos
# This file is auto-generated by the .common_files/generate_gitignore.rb file. If you edit it by hand, it will
# be overwritten the next time that script is run. You should just edit the script to be correct.

  eos
end 



######
# The Real Program
#####


raise "This script is only valid if run from the root of the common files. You ran it from #{Dir.pwd}" unless common_files_path == Dir.pwd

File.open(".gitignore", "w+") do |f|
  f.puts disclaimer
  
  #Ignore Everything
  f.puts "*"

  # Except This Stuff
  f.puts "!.gitignore"
  directories_in_the_common_files.each do |dir|
    f.puts ignore_lines_for_a_directory(dir)
  end
end

directories_in_the_common_files.each do |dir|
  File.open("#{dir.name}/.gitignore","w+") do |f|
    f.puts disclaimer
    f.puts "!**"
    ["*svn", "*~"].each {|exclusion| f.puts exclusion }
    f.puts exceptions_to_the_exception[dir.name].join("\n") if exceptions_to_the_exception[dir.name]
  end
end
