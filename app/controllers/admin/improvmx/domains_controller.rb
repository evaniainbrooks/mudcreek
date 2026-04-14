module Admin
  module Improvmx
    class DomainsController < Admin::BaseController
      def create
        authorize(::Improvmx::Domain, policy_class: ::Improvmx::DomainPolicy)
        ProvisionImprovmxDomainJob.perform_later(Current.tenant.id)
        redirect_to admin_email_aliases_path, notice: "Domain provisioning has been enqueued."
      end

      def verify
        authorize(::Improvmx::Domain, :create?, policy_class: ::Improvmx::DomainPolicy)
        CheckImprovmxDomainJob.perform_later(Current.tenant.id)

        render turbo_stream: turbo_stream.replace(
          "improvmx-status",
          partial: "admin/email_aliases/status",
          locals: { domain: ::Improvmx::Domain.find_by(tenant: Current.tenant), checking: true }
        )
      end
    end
  end
end
