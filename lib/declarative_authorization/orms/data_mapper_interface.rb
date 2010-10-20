module Authorization
  module Orms
    module DataMapperInterface

      def find(model_class, id)
        model_class.send(:get, id)
      end

    end
  end
end

