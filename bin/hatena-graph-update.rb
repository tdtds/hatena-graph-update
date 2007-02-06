#!/usr/bin/env ruby
require 'optparse'
require 'ostruct'
require 'time'
require 'hatena/api/graph'

Version = '0.0.1'

def error_exit( msg, code = -1 )
	$stderr.puts( "#{File::basename $0}: #{msg}" )
	exit( code )
end

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
	opt.on( '-h', '--help' ) do |v|
		puts <<-USAGE.gsub( /^\t\t/, '' )
		hatena-graph-update: sending data to hatena graph service.
		usage:
		   #{File.basename( $0 )} [-u id] [-p pass] [-d date] graph [data...]
		   
		   -u id, --user         : user ID of hatena service.
		   -p password, --passwd : password of hatena service.
		   -d date, --date       : date of data. (default TODAY)
		   graph                 : name of graph on hatena.
		   data                  : data in numeric. (default from STDIN)
		   
		   If no --user option specified, this comment try to get it from ~/.netrc
		   machine as 'hatena.ne.jp'.
		   
		Copyright (C) 2007 by TADA Tadashi <sho@spc.gr.jp>
		Distributed under GPL.
		
		USAGE
		exit
	end
	opt.parse!
end
Opt.graph = ARGV.shift
if ARGV.length == 0 then # get from stdin
	while l = gets
		Opt.data += l.to_f
	end
else
	ARGV.each {|arg| Opt.data += arg.to_f }
end

unless Opt.user then
	require 'net/netrc'
	if netrc = Net::Netrc.locate( 'hatena.ne.jp' ) then
		Opt.user = netrc.login
		Opt.pass = netrc.password
	else
		error_exit( 'no hatena.ne.jp entry in .netrc.' )
	end
end

error_exit( 'no user id specified.' ) unless Opt.user
error_exit( 'no password specified.' ) unless Opt.pass
error_exit( 'no graph name specified.' ) unless Opt.graph

g = Hatena::API::Graph::new( Opt.user, Opt.pass )
g.post( Opt.graph, Opt.date, Opt.data )
