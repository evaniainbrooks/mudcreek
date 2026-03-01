module Admin::DeliveryMethodsHelper
  def delivery_method_inline_edit_price_cell(dm)
    errors  = dm.errors[:price_cents]
    in_edit = errors.any?

    display = tag.span(
      dm.price_cents.zero? ? tag.span("Free", class: "badge text-bg-success") : humanized_money_with_symbol(dm.price, no_cents_if_whole: false),
      class: "inline-editable",
      hidden: in_edit,
      data: {
        "inline-edit-target" => "display",
        action: "click->inline-edit#edit",
        value: dm.price&.to_f.to_s
      })

    form = tag.div(hidden: !in_edit, data: { "inline-edit-target" => "form" }) do
      form_with(url: admin_delivery_method_path(dm), method: :patch, scope: :delivery_method) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          tag.div(class: "input-group input-group-sm") do
            tag.span("$", class: "input-group-text") +
            f.number_field(:price, value: dm.price&.to_f,
              class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
              min: "0", step: "0.01",
              style: "max-width: 100px",
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

    tag.div(id: "#{dom_id(dm)}_price", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def delivery_method_toggle_active_cell(dm)
    tag.div(id: "#{dom_id(dm)}_active") do
      button_to admin_delivery_method_path(dm), method: :patch,
          params: { delivery_method: { active: !dm.active } },
          class: "btn btn-sm #{dm.active? ? "btn-success" : "btn-outline-secondary"}" do
        tag.i("", class: "bi #{dm.active? ? "bi-check-circle-fill" : "bi-circle"} me-1") +
          (dm.active? ? "Active" : "Inactive")
      end
    end
  end

  def delivery_method_toggle_address_required_cell(dm)
    tag.div(id: "#{dom_id(dm)}_address_required") do
      button_to admin_delivery_method_path(dm), method: :patch,
          params: { delivery_method: { address_required: !dm.address_required } },
          class: "btn btn-sm #{dm.address_required? ? "btn-success" : "btn-outline-secondary"}" do
        tag.i("", class: "bi #{dm.address_required? ? "bi-check-circle-fill" : "bi-circle"} me-1") +
          (dm.address_required? ? "Required" : "Not required")
      end
    end
  end

  def render_delivery_methods_table(delivery_methods:)
    table = ::TableComponent.new(rows: delivery_methods)
    table.with_column("Name") { |dm| inline_edit_cell(dm, :name, dm.name, url: admin_delivery_method_path(dm), scope: :delivery_method) }
    table.with_column("Price") { |dm| delivery_method_inline_edit_price_cell(dm) }
    table.with_column("Active") { |dm| delivery_method_toggle_active_cell(dm) }
    table.with_column("Address required") { |dm| delivery_method_toggle_address_required_cell(dm) }
    table.with_column("Actions", html_class: "text-end") do |dm|
      button_to(admin_delivery_method_path(dm), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Delete \"#{dm.name}\"?" } }) do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
