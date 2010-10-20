# Authorization::AuthorizationInModel
require File.dirname(__FILE__) + '/authorization.rb'

module Authorization

  module AuthorizationInModel

    def self.included(base)
      begin
        orm_module = "Authorization::#{Authorization.orm.to_s.camelize}Authorization"
        base.send(:include, orm_module.constantize)
        base.module_eval do

          # Activates model security for the current model.  Then, CRUD operations
          # are checked against the authorization of the current user.  The
          # privileges are :+create+, :+read+, :+update+ and :+delete+ in the
          # context of the model.  By default, :+read+ is not checked because of
          # performance impacts, especially with large result sets.
          #
          #   class User < ActiveRecord::Base
          #     using_access_control
          #   end
          #
          # If an operation is not permitted, a Authorization::AuthorizationError
          # is raised.
          #
          # To activate model security on all models, call using_access_control
          # on ActiveRecord::Base
          #   ActiveRecord::Base.using_access_control
          #
          # Available options
          # [:+context+] Specify context different from the models table name.
          # [:+include_read+] Also check for :+read+ privilege after find.
          #
          def self.using_access_control (options = {})
            options = {
              :context => nil,
              :include_read => false
            }.merge(options)

            class_eval do
              [:create, :update, [:destroy, :delete]].each do |action, privilege|
                send(:"before_#{action}") do |object|
                  Authorization::Engine.instance.permit!(privilege || action,
                    :object => object, :context => options[:context])
                end
              end

              if options[:include_read]
                # after_find is only called if after_find is implemented
                after_find do |object|
                  Authorization::Engine.instance.permit!(:read, :object => object,
                                                         :context => options[:context])
                end

                if Rails.version < "3"
                  def after_find; end
                end
              end

              def self.using_access_control?
                true
              end
            end
          end

          # Returns true if the model is using model security.
          def self.using_access_control?
            false
          end
        end

      rescue StandardError => e
        msg = "Error loading ORM #{Authorization.orm.inspect}"
        msg += "\n#{e}\n#{e.backtrace.join("\n")}"
        raise StandardError.new(msg)
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
