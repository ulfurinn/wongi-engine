module Wongi::Engine
  module CoreExt
    module ClassMethods
      def attr_predicate(*names)
        names_hash = names.inject({}) do |hash, element|
          if Hash === element
            hash.merge element
          else
            hash[element] = false
            hash
          end
        end

        names_hash.each do |name, def_value|
          varname = "@#{name}".to_sym
          predname = "#{name}?".to_sym
          setname = "#{name}=".to_sym
          exclname = "#{name}!".to_sym
          noexclname = "no_#{name}!".to_sym

          define_method predname do
            if instance_variable_defined?(varname)
              instance_variable_get(varname)
            else
              def_value
            end
          end

          define_method setname do |newvalue|
            instance_variable_set(varname, newvalue == true)
          end

          define_method exclname do
            instance_variable_set(varname, true)
          end

          define_method noexclname do
            instance_variable_set(varname, false)
          end
        end
      end

      def abstract(name)
        define_method name do |*args|
          raise NoMethodError.new "#{name} is not implemented for #{self.class.name}", name
        end
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end
  end
end
