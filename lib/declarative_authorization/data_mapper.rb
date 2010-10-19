module Authorization
  module DataMapperAuthorization

    def self.included(base) # :nodoc:

      def self.with_permissions_to(*args)
        raise NotImplementedError.new("No model support for DataMapper yet")
      end

      def self.using_access_control(options={})
        raise NotImplementedError.new("No model support for DataMapper yet")
      end

      def self.using_access_control?
        raise NotImplementedError.new("No model support for DataMapper yet")
      end
    end

  end
end
