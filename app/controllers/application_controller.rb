class ApplicationController < ActionController::API
  include Response
  rescue_from Catalog::TopologyError, :with => :topology_service_error
  rescue_from Catalog::NotAuthorized, :with => :forbidden_error
  rescue_from ManageIQ::API::Common::IdentityError, :with => :unauthorized_error

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      begin
        ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
      rescue KeyError
        json_response({ :message => 'Unauthorized' }, :unauthorized)
      rescue Catalog::NoTenantError
        json_response({ :message => 'Unauthorized' }, :unauthorized)
      end
    end
  end

  def current_tenant(current_user)
    tenant = current_user.tenant
    found_tenant = Tenant.find_or_create_by(:external_tenant => tenant) if tenant.present?
    return found_tenant if found_tenant
    raise Catalog::NoTenantError
  end

  def topology_service_error(err)
    render :json => {:message => err.message}, :status => :internal_server_error
  end

  def forbidden_error(err)
    render :json => {:message => err.message}, :status => :forbidden
  end

  def unauthorized_error(err)
    render :json => {:message => err.message}, :status => :unauthorized
  end
end
