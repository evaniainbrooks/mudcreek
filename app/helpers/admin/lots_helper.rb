module Admin::LotsHelper
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
          tag.div(class: "input-group input-group-sm") do
            f.select(:owner_id, users.map { [ it.email_address, it.id ] },
              {},
              class: "form-select form-select-sm #{"is-invalid" if errors.any?}") +
            f.button(type: "submit", class: "btn btn-outline-primary") do
              tag.i("", class: "bi bi-check-lg")
            end
          end
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(lot)}_owner_id", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def lot_placeholder_cell(lot)
    tag.div(id: "#{dom_id(lot)}_listing_placeholder") do
      if lot.listing_placeholder.attached?
        tag.div(class: "d-flex align-items-center gap-2") do
          image_tag(lot.listing_placeholder.variant(resize_to_fill: [ 80, 50 ]), class: "rounded", style: "object-fit: cover") +
          button_to(admin_lot_listing_placeholder_path(lot), method: :delete, class: "btn btn-sm btn-outline-danger p-1 lh-1",
            form: { data: { turbo_confirm: "Remove placeholder image?" } }) do
            tag.i("", class: "bi bi-x-lg")
          end
        end
      else
        tag.div(data: { controller: "direct-upload" }) do
          form_with(url: admin_lot_path(lot), method: :patch, scope: :lot) do |f|
            tag.div(class: "input-group input-group-sm") do
              f.file_field(:listing_placeholder, accept: "image/*", direct_upload: true,
                class: "form-control form-control-sm") +
              f.button(type: "submit", class: "btn btn-outline-primary") do
                tag.i("", class: "bi bi-upload")
              end
            end
          end +
          tag.div(data: { "direct-upload-target": "progressContainer" }, hidden: true)
        end
      end
    end
  end

  def lot_commission_rate_cell(lot)
    value = lot.commission_rate&.to_s
    errors = lot.errors[:commission_rate]
    in_edit = errors.any?

    display = tag.span(value ? "#{value}%" : "—",
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
          tag.div(class: "input-group input-group-sm", style: "width: 110px") do
            f.number_field(:commission_rate, value: value,
              class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
              min: "0", max: "100", step: "1",
              placeholder: "—",
              data: {
                "inline-edit-target" => "input",
                action: "keydown->inline-edit#keydown"
              }) +
            tag.span("%", class: "input-group-text") +
            f.button(type: "submit", class: "btn btn-outline-primary") do
              tag.i("", class: "bi bi-check-lg")
            end
          end
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(lot)}_commission_rate", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def lot_seller_fee_cell(lot)
    cents = lot.seller_fee_cents
    value = cents ? "%.2f" % (cents / 100.0) : nil
    symbol = Money::Currency.new(Money.default_currency).symbol
    errors = lot.errors[:seller_fee]
    in_edit = errors.any?

    display = tag.span(value ? "#{symbol}#{value}" : "—",
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
          tag.div(class: "input-group input-group-sm", style: "width: 130px") do
            tag.span(symbol, class: "input-group-text") +
            f.number_field(:seller_fee, value: value,
              class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
              step: "0.01", min: "0",
              placeholder: "—",
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

    tag.div(id: "#{dom_id(lot)}_seller_fee", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def render_lots_table(lots:, users:)
    table = ::TableComponent.new(rows: lots)
    table.with_column("Name") { |lot| inline_edit_cell(lot, :name, lot.name, url: admin_lot_path(lot), scope: :lot) }
    table.with_column("Number") { |lot| inline_edit_cell(lot, :number, lot.number.to_s, url: admin_lot_path(lot), scope: :lot) }
    table.with_value_column("Owner") { it.owner }
    table.with_column("Placeholder") { |lot| lot_placeholder_cell(lot) }
    table.with_column("State") { |lot| tag.span(lot.state, class: "badge text-bg-secondary") }
    table.with_column("Commission") { |lot| lot_commission_rate_cell(lot) }
    table.with_column("Seller Fee") { |lot| lot_seller_fee_cell(lot) }
    table.with_column("Listings") do |lot|
      count = lot.listings.size
      link_to(admin_listings_path(q: { lot_id_eq: lot.id }), class: "btn btn-sm btn-outline-secondary") do
        tag.i("", class: "bi bi-list-ul me-1") + "Show #{count} Listings"
      end
    end
    table.with_column("Admin Notes") { |lot| inline_edit_cell(lot, :admin_notes, lot.admin_notes.to_s, url: admin_lot_path(lot), scope: :lot) }
    table.with_column("Settlement") do |lot|
      if lot.settlement
        link_to("View", admin_lot_settlement_path(lot), class: "btn btn-sm btn-outline-primary")
      else
        tag.span("—", class: "text-muted")
      end
    end
    table.with_column("Actions", html_class: "text-end") do |lot|
      button_to(admin_lot_path(lot), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Delete lot \"#{lot.name}\"? Listings will be unassigned." } }) do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
