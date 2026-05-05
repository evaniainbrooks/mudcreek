class Admin::Listings::VariantsController < Admin::BaseController
  before_action :set_listing
  before_action :set_variant, only: [ :edit, :update ]

  def create
    Listings::VariantGenerator.call(listing: @listing)
    redirect_to edit_admin_listing_path(@listing), notice: t(".notice")
  end

  def edit
    @variant.build_gallery unless @variant.gallery
  end

  def update
    if @variant.update(variant_params)
      redirect_to edit_admin_listing_variant_path(@listing, @variant), notice: "Gallery updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end

  def set_variant
    @variant = @listing.variants
      .includes(gallery: { photos_attachments: :blob })
      .find(params[:id])
  end

  def variant_params
    p = params.require(:listings_variant).permit(
      gallery_attributes: [ :id, :name, photos: [] ]
    )
    if (ga = p[:gallery_attributes])
      ga.delete(:photos) if Array(ga[:photos]).all?(&:blank?)
    end
    p
  end
end
