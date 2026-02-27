module Admin::LotsHelper
  def lot_inline_edit_cell(lot, field, value)
    errors = lot.errors[field]
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
      form_with(url: admin_lot_path(lot), method: :patch, scope: :lot) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          f.text_field(field, value: value,
            class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
            data: {
              "inline-edit-target" => "input",
              action: "keydown->inline-edit#keydown blur->inline-edit#blur"
            })
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(lot)}_#{field}", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def lot_inline_edit_owner_cell(lot, users)
    errors = lot.errors[:owner]
    in_edit = errors.any?

    display = tag.span(lot.owner.email_address,
      class: "inline-editable",
      hidden: in_edit,
      data: {
        "inline-edit-target" => "display",
        action: "click->inline-edit#edit",
        value: lot.owner_id.to_s
      })

    form = tag.div(hidden: !in_edit, data: { "inline-edit-target" => "form" }) do
      form_with(url: admin_lot_path(lot), method: :patch, scope: :lot) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          f.select(:owner_id, users.map { [it.email_address, it.id] },
            {},
            class: "form-select form-select-sm #{"is-invalid" if errors.any?}",
            data: { action: "change->inline-edit#submit" })
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(lot)}_owner_id", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def render_lots_table(lots:, users:)
    table = ::TableComponent.new(rows: lots)
    table.with_column("Name") { |lot| lot_inline_edit_cell(lot, :name, lot.name) }
    table.with_column("Number") { |lot| lot_inline_edit_cell(lot, :number, lot.number.to_s) }
    table.with_column("Owner") { |lot| lot_inline_edit_owner_cell(lot, users) }
    table.with_value_column("Listings") { it.listings.size }
    table.with_column("Actions", html_class: "text-end") do |lot|
      button_to admin_lot_path(lot), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Delete lot \"#{lot.name}\"? Listings will be unassigned." } } do
          content_tag(:i, "", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
