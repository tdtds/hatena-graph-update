#!/usr/bin/env ruby

#
# hatena-graph-update
#
# Copyright (C) 2009 by TADA Tadashi <t@tdtds.jp>
# Distributed under GPL.
#

begin
	require 'rubygems'
rescue LoadError
end
require 'optparse'
require 'ostruct'
require 'time'
require 'pathname'
require 'yaml'
require 'hatena/api/graph'

Version = '1.2.0'

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
Opt.date = Date::today
Opt.append = false
Opt.graph = nil
Opt.data = 0.0

ARGV.options do |opt|
	opt.on( '-u HATENA_ID', '--user' ) {|v| Opt.user = v }
	opt.on( '-p PASSWD', '--passwd' )  {|v| Opt.pass = v }
	opt.on( '-d DATE', '--date' )      {|v| Opt.date = Date::parse( v ) }
	opt.on( '-a', '--append' )         {|v| Opt.append = true }
	opt.on( '-h', '--help' ) do |v|
		puts <<-USAGE.gsub( /^\t\t/, '' )
		hatena-graph-update: sending data to hatena graph service.
		usage:
		   #{File.basename( $0 )} [-u id] [-p pass] [-d date] [-a] graph [data...]
		   
		   -u id, --user         : user ID of hatena service.
		   -p password, --passwd : password of hatena service.
		   -d date, --date       : date of data. (default TODAY)
		   -a                    : append to data of same day.
		   graph                 : name of graph on hatena.
		   data                  : data in numeric. (default from STDIN)
		   
		   If no --user option specified, this command will try to get it from
         ~/.pit or ~/.netrc machine as 'hatena.ne.jp'.
		   
		Copyright (C) 2009 by TADA Tadashi <t@tdtds.jp>
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
	auth_entry = 'hatena.ne.jp'
	begin
		require 'pit'
		conf = Pit::get( auth_entry, :require => {
			'username' => 'Your Hatena ID',
			'password' => 'Your Hatena Password'
		} )
		Opt.user = conf['username']
		Opt.pass = conf['password']
	rescue LoadError
		begin
			require 'net/netrc'
			if netrc = Net::Netrc.locate( auth_entry ) then
				Opt.user = netrc.login
				Opt.pass = netrc.password
			else
				error_exit( 'no hatena.ne.jp entry in .netrc.' )
			end
		rescue LoadError
		end
	end
end
error_exit( 'no user id specified.' ) if not Opt.user or Opt.user.length == 0
error_exit( 'no password specified.' ) if not Opt.pass or Opt.pass.length == 0

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

begin
	g = Hatena::API::Graph::new( Opt.user, Opt.pass )

	if Opt.append then
		require 'yaml'
		datas = YAML::load( YAML::dump( g.get_data( Opt.graph ) ) )
		Opt.data += datas[Opt.date] || 0.0
	end

	g.post( Opt.graph, Opt.date, Opt.data )
rescue Hatena::API::GraphError
	error_exit( $!.message )
end
