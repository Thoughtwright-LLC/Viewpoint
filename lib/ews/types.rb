module Viewpoint::EWS
  module Types

    @@key_paths = {} #blank by default, set in type classes
    @@key_types = {} #blank by default, set in type classes
    @@key_alias = {} #blank by default, set in type classes

    # @param [SOAP::ExchangeWebService] ews the EWS reference
    # @param [Hash] ews_item the EWS parsed response document
    def initialize(ews, ews_item)
      @ews      = ews
      @ews_item = ews_item
      @shallow      = true
    end

    def method_missing(method_sym, *arguments, &block)
      if method_keys.include?(method_sym)
        type_convert( method_sym, resolve_method(method_sym) )
      else
        super
      end
    end

    def shallow?
      @shallow
    end

    def auto_deepen?
      ews.auto_deepen
    end

    def deepen!
      if shallow?
        self.get_all_properties!
        @shallow = false
        true
      end
    end
    alias_method :enlighten!, :deepen!

    # @see http://www.ruby-doc.org/core/classes/Object.html#M000333
    def respond_to?(method_sym, include_private = false)
      if method_keys.include?(method_sym)
        true
      else
        super
      end
    end

    def methods(include_super = true)
      super + ews_methods
    end

    def ews_methods
      key_paths.keys + key_alias.keys
    end


    private


    def ews
      @ews
    end

    def class_by_name(cname)
      if(cname.instance_of? Symbol)
        cname = cname.to_s.camel_case
      end
      Viewpoint::EWS::Types.const_get(cname)
    end

    def type_convert(key,str)
      return nil if str.nil?
      key_types[key] ? key_types[key].call(str) : str
    end

    def resolve_method
      begin
        resolve_key_path(@ews_item, method_path(method_sym))
      rescue
        if shallow? && auto_deepen?
          enlighten!
          retry
        end
      end
    end

    def resolve_key_path(hsh, path)
      k = path.first
      return hsh[k] if path.length == 1
      resolve_key_path(hsh[k],path[1..-1])
    end

    def key_paths
      self.class.key_paths
    end

    def key_types
      self.class.key_types
    end

    def key_alias
      self.class.key_alias
    end

    def method_keys
      key_paths.keys + key_alias.keys
    end

    # Resolve the method path with or without an alias
    def method_path(sym)
      key_paths[key_alias[sym] || sym]
    end

  end
end