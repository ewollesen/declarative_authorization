module Authorization
  module Orms
    autoload :ActiveRecordInterface, File.dirname(__FILE__) + "/orms/active_record_interface.rb"
    autoload :DataMapperInterface, File.dirname(__FILE__) + "/orms/data_mapper_interface.rb"

    class Interface

      case Authorization.orm
      when :active_record
        include Authorization::Orms::ActiveRecordInterface
      when :data_mapper
        include Authorization::Orms::DataMapperInterface
      else
        raise NotImplementedError.new("Unsupported ORM #{Authorization.orm.pretty_inspect}")
      end

      def method_missing(method, *args)
        case method.to_s
        when /find/
          raise NotImplementedError.new("You must implement a find method for your ORM Interface: #{Authorization.orm.pretty_inspect}")
        end
        super
      end
    end
  end
end
