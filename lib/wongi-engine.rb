module Wongi
  module Engine

    def self.create
      Network.new
    end

  end

  # pre-declare things to avoid undefined constants
  module RDF

    class Document; end
    class Statement; end
    class Node; end

  end
end

require 'wongi-engine/version'
require 'wongi-engine/core_ext'
require 'wongi-engine/error'
require 'wongi-engine/template'
require 'wongi-engine/wme'
require 'wongi-engine/wme_match_data'
require 'wongi-engine/token'
require 'wongi-engine/filter'
require 'wongi-engine/alpha_memory'
require 'wongi-engine/beta'
require 'wongi-engine/dsl'
require 'wongi-engine/ruleset'
require 'wongi-engine/compiler'
require 'wongi-engine/data_overlay'
require 'wongi-engine/enumerators'
require 'wongi-engine/network'
require 'wongi-engine/graph'
