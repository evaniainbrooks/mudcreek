class Admin::AttachmentsListComponent < ViewComponent::Base
  # Renders a simple list of ActiveStorage attachments with linked filenames and
  # optional per-row delete buttons.
  #
  # attachments   – collection of ActiveStorage::Attachment objects
  # delete_path   – optional proc/lambda receiving each attachment, returning the
  #                 path for the delete action, e.g.:
  #                   ->(a) { admin_listing_gallery_attachment_path(listing, a) }
  # delete_method – Turbo method for the delete link (default :delete)
  #
  # Example:
  #   render Admin::AttachmentsListComponent.new(
  #     attachments:   listing.gallery.photos_attachments,
  #     delete_path:   ->(a) { admin_listing_gallery_attachment_path(listing, a) }
  #   )

  def initialize(attachments:, delete_path: nil, delete_method: :delete)
    @attachments   = attachments
    @delete_path   = delete_path
    @delete_method = delete_method
  end

  def render?
    @attachments.any?
  end

  private

  ICON_MAP = {
    "application/pdf"      => "bi-file-pdf",
    "application/msword"   => "bi-file-word",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "bi-file-word",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       => "bi-file-excel"
  }.freeze

  def icon_for(attachment)
    ct = attachment.content_type.to_s
    return "bi-image"        if ct.start_with?("image/")
    return "bi-camera-video" if ct.start_with?("video/")
    ICON_MAP.fetch(ct, "bi-file-earmark")
  end

  def delete_path_for(attachment)
    @delete_path&.call(attachment)
  end
end
