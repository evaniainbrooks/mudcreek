module Admin
  class SenderSignaturesController < Admin::BaseController
    def index
      authorize(::Postmark::Domain, policy_class: ::Postmark::DomainPolicy)
      @root_domain = PublicSuffix.domain(Current.tenant.custom_domain) if Current.tenant.custom_domain.present?
      @postmark_domain = ::Postmark::Domain.find_by(tenant: Current.tenant)
    end
  end
end
