# Authorization::AuthorizationInModel
require File.dirname(__FILE__) + '/authorization.rb'
require File.dirname(__FILE__) + '/active_record.rb'

module Authorization

  module AuthorizationInModel

    def self.included(base)
      case Authorization.orm
      when :active_record
        base.send(:include, ActiveRecordAuthorization)
      else
        raise NotImplementedError.new("Unhandled ORM #{Authorization.orm}")
      end
    end

    # If the user meets the given privilege, permitted_to? returns true
    # and yields to the optional block.
    def permitted_to? (privilege, options = {}, &block)
      options = {
        :user =>  Authorization.current_user,
        :object => self
      }.merge(options)
      Authorization::Engine.instance.permit?(privilege,
          {:user => options[:user],
           :object => options[:object]},
          &block)
    end

    # Works similar to the permitted_to? method, but doesn't accept a block
    # and throws the authorization exceptions, just like Engine#permit!
    def permitted_to! (privilege, options = {} )
      options = {
        :user =>  Authorization.current_user,
        :object => self
      }.merge(options)
      Authorization::Engine.instance.permit!(privilege,
          {:user => options[:user],
           :object => options[:object]})
    end

  end
end
