#!/usr/bin/ruby
#
# From https://gist.github.com/happymcplaksin/8e262e98db6bd28d0ce9
# ------------------------------------------------------------------------------
require 'rubygems'
require 'json'
require 'yaml'

user = ARGV[0] || %x{id -u -n}.strip

if user == 'root'
    dir = '/opt/puppetlabs/puppet/cache/client_data/catalog/'
else
    dir = "/home/#{user}/.puppetlabs/var/client_data/catalog/"
end

unless File.directory? dir
  fail "Sorry, I don't know where to find the catalog for user '#{user}'"
end

cat = JSON.load(File.readlines("#{dir}/#{ENV['HOSTNAME']}.json").join)
print cat.to_yaml
