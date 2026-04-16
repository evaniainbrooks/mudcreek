class Admin::Listings::CopiesController < Admin::BaseController
  before_action :set_listing

  def create
    copy = @listing.dup
    copy.name = "Copy of #{@listing.name}"
    copy.published = false
    copy.position = nil
    copy.hashid = nil

    Listing.transaction do
      copy.description = @listing.description.body
      copy.save!
      @listing.category_assignments.each { |ca| copy.category_assignments.create!(category: ca.category) }
      @listing.properties.each { |p| copy.properties.create!(p.attributes.slice("name", "value", "icon", "position")) }
      @listing.rental_rate_plans.each { |rp| copy.rental_rate_plans.create!(rp.attributes.slice("label", "duration_minutes", "price_cents")) }
      if (addr = @listing.address)
        copy.create_address(addr.attributes.except("id", "addressable_id", "addressable_type", "created_at", "updated_at"))
      end
      if (src = @listing.gallery)
        gallery = copy.create_gallery!(name: copy.name)
        gallery.photos.attach(src.photos.map(&:blob))       if src.photos.attached?
        gallery.videos.attach(src.videos.map(&:blob))       if src.videos.attached?
        gallery.documents.attach(src.documents.map(&:blob)) if src.documents.attached?
      end
    end

    redirect_to edit_admin_listing_path(copy), notice: "Listing copied. Review and publish when ready."
  end

  private

  def set_listing
    @listing = Listing
      .includes(:category_assignments, :properties, :rental_rate_plans, :address,
                gallery: { photos_attachments: :blob, videos_attachments: :blob, documents_attachments: :blob })
      .find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end
end
