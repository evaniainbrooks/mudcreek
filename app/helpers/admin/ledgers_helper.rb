module Admin::LedgersHelper
  def render_ledgers_table(ledgers:)
    table = TableComponent.new(rows: ledgers)
    table.with_column("Name") { |l| link_to l.name, admin_ledger_path(l), class: "fw-medium text-decoration-none" }
    table.with_column("Description") { |l| l.description.presence || content_tag(:span, "—", class: "text-muted") }
    table.with_column("Entries", html_class: "text-center") { |l| l.entries.count }
    table.with_column("Actions", html_class: "text-end") do |l|
      safe_join([
        link_to("Edit", edit_admin_ledger_path(l), class: "btn btn-sm btn-outline-primary me-1"),
        button_to("Delete", admin_ledger_path(l), method: :delete,
          class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Delete \"#{l.name}\" and all its entries?" } })
      ])
    end
    render(table)
  end

  def render_entries_table(entries:)
    table = TableComponent.new(rows: entries, tbody_id: "ledger-entries-tbody")
    table.with_column("Date") do |e|
      tz = Current.tenant&.timezone.presence
      localized = tz ? e.recorded_at.in_time_zone(tz) : e.recorded_at.utc
      content_tag(:time, localized.strftime("%b %-d, %Y %H:%M"),
        datetime: e.recorded_at.iso8601, class: "text-muted")
    end
    table.with_column("Description") { |e| h(e.description) }
    table.with_column("Type") { |e| entry_type_badge(e) }
    table.with_column("Amount") do |e|
      e.amount ? number_to_currency(e.amount) : content_tag(:span, "—", class: "text-muted")
    end
    table.with_column("Memo") { |e| e.memo.presence || content_tag(:span, "—", class: "text-muted") }
    table.with_value_column("Recorded by") { |e| e.user }
    table.with_column("", html_class: "text-end") do |e|
      button_to admin_ledger_entry_path(@ledger, e), method: :delete,
        class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Remove this entry?" } } do
        content_tag(:i, "", class: "bi bi-trash")
      end
    end
    render(table)
  end

  def entry_type_badge(entry)
    if entry.credit?
      content_tag(:span, "Credit", class: "badge text-bg-success")
    else
      content_tag(:span, "Debit", class: "badge text-bg-danger")
    end
  end
end
