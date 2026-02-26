module ApplicationHelper
  FLASH_CLASS_MAP = {
    "notice"  => "success",
    "alert"   => "danger",
    "warning" => "warning",
    "info"    => "info"
  }.freeze

  DOCUMENT_ICON_MAP = {
    "application/pdf"                                                             => "bi-file-pdf",
    "application/msword"                                                          => "bi-file-word",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"     => "bi-file-word",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           => "bi-file-excel"
  }.freeze

  def bootstrap_flash_class(type)
    FLASH_CLASS_MAP.fetch(type.to_s, "secondary")
  end

  def document_icon_class(content_type)
    DOCUMENT_ICON_MAP.fetch(content_type.to_s, "bi-file-earmark")
  end
end
