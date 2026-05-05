class Admin::Galleries::AttachmentsController < Admin::BaseController
  before_action :set_gallery
  before_action :set_attachment

  def destroy
    @attachment.purge_later
    redirect_to edit_admin_gallery_path(@gallery), notice: t(".notice", filename: @attachment.filename)
  end

  private

  def set_gallery
    @gallery = Gallery.find(params[:gallery_id])
    authorize(@gallery, :update?)
  end

  def set_attachment
    @attachment = ActiveStorage::Attachment.find_by!(record: @gallery, id: params[:id])
  end
end
