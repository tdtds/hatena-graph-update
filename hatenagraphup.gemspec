# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hatena/graph-update"

Gem::Specification.new do |s|
  s.name        = "hatenagraphup"
  s.version     = Hatena::GraphUpdate::VERSION
  s.authors     = ["TADA Tadashi"]
  s.email       = ["t@tdtds.jp"]
  s.homepage    = "https://github.com/tdtds/hatena-graph-update"
  s.summary     = %q{Hatena Graph updater}
  s.description = %q{Updating Hatena Graph via HTTP.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "hatenaapigraph"
end
