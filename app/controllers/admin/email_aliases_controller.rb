module Admin
  class EmailAliasesController < Admin::BaseController
    def index
      authorize(EmailAlias, policy_class: EmailAliasPolicy)
      @result = Rails.cache.read("improvmx_domain_check_#{Current.tenant.id}")
      @root_domain = PublicSuffix.domain(Current.tenant.custom_domain) if Current.tenant.custom_domain.present?
    end

    def verify
      authorize(EmailAlias, :create?, policy_class: EmailAliasPolicy)
      CheckImprovmxDomainJob.perform_later(Current.tenant.id)

      render turbo_stream: turbo_stream.replace(
        "improvmx-status",
        partial: "admin/email_aliases/status",
        locals: { result: { checking: true }, tenant: Current.tenant }
      )
    end
  end
end
