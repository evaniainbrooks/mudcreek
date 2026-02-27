class Admin::Listings::AttachmentsController < Admin::BaseController
  before_action :set_listing
  before_action :set_attachment

  def destroy
    @attachment.purge_later
    redirect_to edit_admin_listing_path(@listing), notice: "#{@attachment.filename} was removed."
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end

  def set_attachment
    @attachment = ActiveStorage::Attachment.find_by!(record: @listing, id: params[:id])
  end
end
