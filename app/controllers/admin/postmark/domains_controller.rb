module Admin
  module Postmark
    class DomainsController < Admin::BaseController
      def create
        authorize(::Postmark::Domain, policy_class: ::Postmark::DomainPolicy)
        ProvisionPostmarkDomainJob.perform_later(Current.tenant.id)
        redirect_to admin_sender_signatures_path, notice: t(".notice")
      end

      def verify
        authorize(::Postmark::Domain, :create?, policy_class: ::Postmark::DomainPolicy)
        VerifyPostmarkDomainJob.perform_later(Current.tenant.id)

        render turbo_stream: turbo_stream.replace(
          "postmark-domain-status",
          partial: "admin/sender_signatures/domain_status",
          locals: { domain: ::Postmark::Domain.find_by(tenant: Current.tenant), checking: true }
        )
      end
    end
  end
end
