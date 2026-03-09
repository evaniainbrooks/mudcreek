module Admin::AuctionRegistrationsHelper
  def render_auction_registrations_index_table(registrations:, q:)
    table = ::TableComponent.new(rows: registrations, tbody_id: "admin-auction-registrations-tbody", ransack_query: q)
    add_auction_registration_columns(table)
    render(table)
  end

  def auction_registration_columns
    add_auction_registration_columns(::TableComponent.new(rows: [])).columns
  end

  def auction_registration_state_inline_cell(registration)
    states = AuctionRegistration.states.keys.map { |s| [s.humanize, s] }
    current = registration.state

    display = tag.span(auction_registration_state_badge(registration),
      style: "cursor: pointer",
      data: { "inline-edit-target" => "display", action: "click->inline-edit#edit" })

    form = tag.div(hidden: true, data: { "inline-edit-target" => "form" }) do
      form_with(url: admin_auction_registration_path(registration), method: :patch, scope: :auction_registration) do |f|
        f.select(:state, states, { selected: current },
          class: "form-select form-select-sm",
          style: "width: auto",
          data: { "inline-edit-target" => "input", action: "change->inline-edit#autoSubmit" })
      end
    end

    tag.div(id: "#{dom_id(registration)}_state", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def auction_registration_notes_inline_cell(registration)
    value = registration.admin_notes
    errors = registration.errors[:admin_notes]

    display = tag.span(value.present? ? value : tag.span("—", class: "text-muted"),
      class: "inline-editable",
      style: "cursor: pointer",
      data: { "inline-edit-target" => "display", action: "click->inline-edit#edit", value: value.to_s })

    form = tag.div(hidden: true, data: { "inline-edit-target" => "form" }) do
      form_with(url: admin_auction_registration_path(registration), method: :patch, scope: :auction_registration) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          tag.div(class: "input-group input-group-sm", style: "min-width: 180px") do
            f.text_field(:admin_notes, value: value,
              class: "form-control form-control-sm",
              placeholder: "Notes…",
              data: { "inline-edit-target" => "input", action: "keydown->inline-edit#keydown" }) +
            f.button(type: "submit", class: "btn btn-outline-primary") { tag.i("", class: "bi bi-check-lg") }
          end
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(registration)}_admin_notes", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  private

  def add_auction_registration_columns(table)
    table.with_column("Auction") { |r| link_to(r.auction.name, admin_auction_path(r.auction)) }
    table.with_value_column("User") { it.user }
    table.with_column("State") { |r| auction_registration_state_inline_cell(r) }
    table.with_column("Notes") { |r| auction_registration_notes_inline_cell(r) }
    table.with_value_column("Registered", sort_attr: :created_at) { it.created_at }
    table.with_value_column("Updated", sort_attr: :updated_at) { it.updated_at }
  end
end
