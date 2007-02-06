#!/usr/bin/env ruby
require 'optparse'
require 'ostruct'
require 'time'
require 'hatena/api/graph'

Opt = OpenStruct::new
Opt.user = nil
Opt.pass = nil
Opt.date = Time::now
Opt.append = false
Opt.graph = nil
Opt.data = 0.0

ARGV.options do |opt|
	opt.on( '-u HATENA_ID', '--user' ) {|v| Opt.user = v }
	opt.on( '-p PASSWD', '--passwd' )  {|v| Opt.pass = v }
	opt.on( '-d DATE', '--date' )      {|v| Opt.date = Time::parse( v ) }
#	opt.on( '-a', '--append' )         {|v| Opt.append = true }
	opt.parse!
end
Opt.graph = ARGV.shift
if ARGV.length == 0 then # get from stdin
	while l = gets
		Opt.data += l.to_f
	end
else
	ARGV.each do |arg|
		Opt.data += arg.to_f
	end
end

unless Opt.user then
	require 'net/netrc'
	if netrc = Net::Netrc.locate( 'hatena.ne.jp' ) then
		Opt.user = netrc.login
		Opt.pass = netrc.password
	else
		$stderr.puts 'no user name.'
		exit
	end
end

g = Hatena::API::Graph::new( Opt.user, Opt.pass )
g.post( Opt.graph, Opt.date, Opt.data )
