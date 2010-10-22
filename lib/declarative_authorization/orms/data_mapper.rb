module Authorization
  module DataMapperAuthorization

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
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
      def with_permissions_to(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        privilege = (args[0] || :read).to_sym
        privileges = [privilege]
        options = {
          :user => Authorization.current_user,
          :context => nil,
          :model => self,
          :engine => nil,
        }.merge(options)
        engine = options[:engine] || Authorization::Engine.instance
        context = if options[:context]
                    options[:context]
                  elsif self.respond_to?(:proxy_reflection)
                    self.proxy_reflection.klass.name.tableize.to_sym
                  elsif self.respond_to?(:decl_auth_context)
                    self.decl_auth_context
                  else
                    self.name.tableize.to_sym
                  end
        user = options[:user] || Authorization.current_user
        engine.permit!(privileges, {:user => user,
                                    :skip_attribute_test => true,
                                    :context => context})

        obligations = engine.obligations(privileges, :user => user, :context => context)
        convert_obligations_to_scopes(obligations)
      end

      def convert_obligations_to_scopes(obligations)
        return self.all if obligations.empty?

        scopes = obligations.inject([]) do |scope, obligation|
          scope << convert_obligation_to_scope(obligation)
        end
        logical_or_scopes(scopes.flatten)
      end

      def convert_obligation_to_scope(obligation)
        scope = {}
        obligation.each_pair do |context, comparison|
          case comparison
          when Hash
            scope[context] = convert_obligation_to_scope(comparison)
          when Array
            scope[context] = parse_comparison(comparison)
          else
            raise NotImplementedError.new("Don't know how to handle comparison #{comparison.pretty_inspect}")
          end
        end

        return scope
      end

      def parse_comparison(comparison)
        operator, value = comparison
        case operator
        when :is, :is_in
          value
        else
          raise NotImplementedError.new("Don't know how to handle operator #{operator.pretty_inspect}")
        end
      end

      def logical_or_scopes(scopes)
        scopes.map! {|scope| self.all(scope)}
        scopes.inject {|combined, scope| combined + scope}.all
      end

    end
  end
end
