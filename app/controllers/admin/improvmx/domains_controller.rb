module Admin
  module Improvmx
    class DomainsController < Admin::BaseController
      def create
        authorize(::Improvmx::Domain, policy_class: ::Improvmx::DomainPolicy)
        ProvisionImprovmxDomainJob.perform_later(Current.tenant.id)
        redirect_to admin_email_aliases_path, notice: "Domain provisioning has been enqueued."
      end
    end
  end
end
