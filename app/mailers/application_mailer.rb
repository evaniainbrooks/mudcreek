class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  def mail(headers = {}, &block)
    Current.tenant ||= infer_tenant
    headers[:from] ||= Current.tenant&.email_address
    super
  end

  private

  # Scan instance variables set by the action method for any MultiTenant record
  # and derive the tenant from it. Runs at mail() time so all ivars are available.
  def infer_tenant
    instance_variables.lazy.filter_map { |v|
      obj = instance_variable_get(v)
      obj.tenant if obj.respond_to?(:tenant)
    }.first
  end
end
