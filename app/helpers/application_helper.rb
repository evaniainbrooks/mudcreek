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

  def inline_edit_cell(record, field, value, url:, scope:)
    errors = record.errors[field]
    in_edit = errors.any?

    display = tag.span(value.presence || "—",
      class: "inline-editable",
      hidden: in_edit,
      data: {
        "inline-edit-target" => "display",
        action: "click->inline-edit#edit",
        value: value.to_s
      })

    form = tag.div(hidden: !in_edit, data: { "inline-edit-target" => "form" }) do
      form_with(url: url, method: :patch, scope: scope) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          tag.div(class: "input-group input-group-sm") do
            f.text_field(field, value: value,
              class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
              data: {
                "inline-edit-target" => "input",
                action: "keydown->inline-edit#keydown"
              }) +
            f.button(type: "submit", class: "btn btn-outline-primary") do
              tag.i("", class: "bi bi-check-lg")
            end
          end
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(record)}_#{field}", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def bootstrap_flash_class(type)
    FLASH_CLASS_MAP.fetch(type.to_s, "secondary")
  end

  def document_icon_class(content_type)
    DOCUMENT_ICON_MAP.fetch(content_type.to_s, "bi-file-earmark")
  end
end
