module ApplicationHelper
  FLASH_CLASS_MAP = {
    "notice"  => "success",
    "alert"   => "danger",
    "warning" => "warning",
    "info"    => "info"
  }.freeze

  def bootstrap_flash_class(type)
    FLASH_CLASS_MAP.fetch(type.to_s, "secondary")
  end
end
