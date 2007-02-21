#!/usr/bin/env ruby

#
# hatena-graph-update
#
# Copyright (C) 2007 by TADA Tadashi <sho@spc.gr.jp>
# Distributed under GPL.
#

require 'optparse'
require 'ostruct'
require 'time'
require 'pathname'
require 'yaml'
require 'hatena/api/graph'

Version = '1.0.0'

def error_exit( msg, code = -1 )
	$stderr.puts( "#{File::basename $0}: #{msg}" )
	exit( code )
end

begin
	require 'hatena/api/graph'
rescue LoadError
	error_exit 'Hatena::Api::Graph not found. See <http://rubyforge.org/projects/hatenaapigraph/>'
end

Opt = OpenStruct::new
Opt.user = nil
Opt.pass = nil
Opt.date = Time::now
Opt.append = false
Opt.cache = nil
Opt.graph = nil
Opt.data = 0.0

ARGV.options do |opt|
	opt.on( '-u HATENA_ID', '--user' ) {|v| Opt.user = v }
	opt.on( '-p PASSWD', '--passwd' )  {|v| Opt.pass = v }
	opt.on( '-d DATE', '--date' )      {|v| Opt.date = Time::parse( v ) }
	opt.on( '-a', '--append' )         {|v| Opt.append = true }
	opt.on( '-c CACHE', '--cache' )    {|v| Opt.cache = v }
	opt.on( '-h', '--help' ) do |v|
		puts <<-USAGE.gsub( /^\t\t/, '' )
		hatena-graph-update: sending data to hatena graph service.
		usage:
		   #{File.basename( $0 )} [-u id] [-p pass] [-d date] [-a -c cache] graph [data...]
		   
		   -u id, --user         : user ID of hatena service.
		   -p password, --passwd : password of hatena service.
		   -d date, --date       : date of data. (default TODAY)
		   -a                    : append to data of same day.
		   -c cache, --cache     : dirctory of data cache for append mode.
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

#
# check user id and password
#
unless Opt.user then
	begin
		require 'net/netrc'
		if netrc = Net::Netrc.locate( 'hatena.ne.jp' ) then
			Opt.user = netrc.login
			Opt.pass = netrc.password
		else
			error_exit( 'no hatena.ne.jp entry in .netrc.' )
		end
	rescue LoadError
	end
end
error_exit( 'no user id specified.' ) unless Opt.user
error_exit( 'no password specified.' ) unless Opt.pass

#
# check graph parameter
#
Opt.graph = ARGV.shift
error_exit( 'no graph name specified.' ) unless Opt.graph

#
# check data
#
if ARGV.length == 0 then # get from stdin
	while l = gets
		Opt.data += l.to_f
	end
else
	ARGV.each {|arg| Opt.data += arg.to_f }
end

#
# check append option
#
if Opt.append then
	unless Opt.cache then
		error_exit( "cache directory dose not specified." )
	end
	cache = Pathname::new( Opt.cache )
	error_exit( "Such as no directory: #{Opt.cache}" ) unless cache.directory?

	datas = Hash::new( 0.0 )
	cache_file = cache + Opt.graph
	cache_file.open {|f| datas.update( YAML::load( f ) ) } rescue false
	Opt.data += datas[Opt.date.strftime( '%Y-%m-%d' )]
	datas[Opt.date.strftime( '%Y-%m-%d' )] = Opt.data
	cache_file.open( 'w' ) {|f| YAML::dump( datas, f ) }
end

begin
	g = Hatena::API::Graph::new( Opt.user, Opt.pass )
	g.post( Opt.graph, Opt.date, Opt.data )
rescue Hatena::API::GraphError
	error_exit( $!.message )
end
