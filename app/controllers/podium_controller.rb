class PodiumController < ApplicationController
  allow_unauthenticated_access

  def index
    set_meta_tags(
      title:       "Podium — White-label commerce platform",
      description: "Podium is a multi-tenant commerce platform for auctions, listings, rentals, and more.",
      og:          { title: "Podium", description: "The white-label commerce platform." }
    )
  end

  def create
    PodiumMailer.contact(
      name:        params[:name],
      email:       params[:email],
      message:     params[:message],
      tenant_name: Current.tenant&.name,
      user_agent:  request.user_agent,
      user_id:     Current.user&.id,
      user_name:   Current.user&.name,
      submitted_at: Time.current.to_fs(:long)
    ).deliver_later

    redirect_to podium_path, notice: "Thanks for reaching out — we'll be in touch soon."
  end
end
