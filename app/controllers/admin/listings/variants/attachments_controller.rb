class Admin::Listings::Variants::AttachmentsController < Admin::BaseController
  before_action :set_listing
  before_action :set_variant
  before_action :set_attachment

  def destroy
    @attachment.purge_later
    redirect_to edit_admin_listing_variant_path(@listing, @variant),
                notice: "#{@attachment.filename} was removed."
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end

  def set_variant
    @variant = @listing.variants.find(params[:variant_id])
  end

  def set_attachment
    @attachment = ActiveStorage::Attachment.find_by!(record: @variant.gallery, id: params[:id])
  end
end
