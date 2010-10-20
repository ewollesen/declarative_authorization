module Authorization
  module Orms
    module ActiveRecordInterface

      def find(model_class, id)
        model_class.send(:find, id)
      end

    end
  end
end

