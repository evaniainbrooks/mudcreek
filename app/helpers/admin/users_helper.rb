module Admin::UsersHelper
  def rank_awards_table(awards)
    t = TableComponent.new(rows: awards)
    t.with_column("Date")       { |a| a.awarded_at.to_fs(:long) }
    t.with_column("Rank")       { |a| a.rank.name }
    t.with_column("Stripes")    { |a| a.stripes }
    t.with_column("Awarded by") { |a| a.awarded_by&.name || content_tag(:span, "—", class: "text-muted") }
    t.with_column("Notes")      { |a| a.notes.presence || content_tag(:span, "—", class: "text-muted") }
    t.with_column("", html_class: "text-end") do |a|
      button_to "Remove", admin_rank_award_path(a), method: :delete,
        class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Remove this promotion record?" } }
    end
    render(t)
  end
end
