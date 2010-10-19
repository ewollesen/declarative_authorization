require File.join(%w{declarative_authorization rails_legacy})
require File.join(%w{declarative_authorization helper})
require File.join(%w{declarative_authorization in_controller})
require File.join(%w{declarative_authorization in_model})

min_rails_version = "2.1.0"
if Rails::VERSION::STRING < min_rails_version
  raise "declarative_authorization requires Rails #{min_rails_version}.  You are using #{Rails::VERSION::STRING}."
end

require File.join(%w{declarative_authorization railsengine}) if defined?(::Rails::Engine)

ActionController::Base.send :include, Authorization::AuthorizationInController
ActionController::Base.helper Authorization::AuthorizationHelper

case Authorization.orm
when :active_record
  ActiveRecord::Base.send :include, Authorization::AuthorizationInModel
else
  raise NotImplementedError.new("Unhandled ORM #{Authorization.orm}")
end
