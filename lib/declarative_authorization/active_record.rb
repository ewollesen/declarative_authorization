require File.dirname(__FILE__) + '/active_record/obligation_scope.rb'

module Authorization
  module ActiveRecordAuthorization

    def self.included(base) # :nodoc:
      #base.extend(ClassMethods)
      base.module_eval do
        scopes[:with_permissions_to] = lambda do |parent_scope, *args|
          options = args.last.is_a?(Hash) ? args.pop : {}
          privilege = (args[0] || :read).to_sym
          privileges = [privilege]
          context =
              if options[:context]
                options[:context]
              elsif parent_scope.respond_to?(:proxy_reflection)
                parent_scope.proxy_reflection.klass.name.tableize.to_sym
              elsif parent_scope.respond_to?(:decl_auth_context)
                parent_scope.decl_auth_context
              else
                parent_scope.name.tableize.to_sym
              end

          user = options[:user] || Authorization.current_user

          engine = options[:engine] || Authorization::Engine.instance
          engine.permit!(privileges, :user => user, :skip_attribute_test => true,
                         :context => context)

          obligation_scope_for( privileges, :user => user,
              :context => context, :engine => engine, :model => parent_scope)
        end

        # Builds and returns a scope with joins and conditions satisfying all obligations.
        def self.obligation_scope_for( privileges, options = {} )
          options = {
            :user => Authorization.current_user,
            :context => nil,
            :model => self,
            :engine => nil,
          }.merge(options)
          engine = options[:engine] || Authorization::Engine.instance

          obligation_scope = ObligationScope.new( options[:model], {} )
          engine.obligations( privileges, :user => options[:user], :context => options[:context] ).each do |obligation|
            obligation_scope.parse!( obligation )
          end

          obligation_scope.scope
        end

        # Named scope for limiting query results according to the authorization
        # of the current user.  If no privilege is given, :+read+ is assumed.
        #
        #   User.with_permissions_to
        #   User.with_permissions_to(:update)
        #   User.with_permissions_to(:update, :context => :users)
        #
        # As in the case of other named scopes, this one may be chained:
        #   User.with_permission_to.find(:all, :conditions...)
        #
        # Options
        # [:+context+]
        #   Context for the privilege to be evaluated in; defaults to the
        #   model's table name.
        # [:+user+]
        #   User to be used for gathering obligations; defaults to the
        #   current user.
        #
        def self.with_permissions_to (*args)
          scopes[:with_permissions_to].call(self, *args)
        end

      end
    end

  end
end
