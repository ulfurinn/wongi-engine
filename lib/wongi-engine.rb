module Wongi
  module Engine
    
    def self.create
      Network.new
    end

  end
end

require 'wongi-engine/version'
require 'wongi-engine/core_ext'
require 'wongi-engine/template'
require 'wongi-engine/wme'
require 'wongi-engine/wme_match_data'
require 'wongi-engine/token'
require 'wongi-engine/filter'
require 'wongi-engine/alpha_memory'
require 'wongi-engine/beta'
require 'wongi-engine/dsl'
require 'wongi-engine/ruleset'
require 'wongi-engine/network'
require 'wongi-engine/graph'
