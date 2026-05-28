module Admin::DisciplinesHelper
  def disciplines_table(disciplines)
    t = TableComponent.new(rows: disciplines)
    t.with_column("Name") { |d| link_to d.name, admin_discipline_path(d) }
    t.with_column("Ranks") { |d| d.ranks.size }
    t.with_column("", html_class: "text-end") do |d|
      content_tag(:div, class: "d-flex gap-1 justify-content-end") do
        safe_join([
          link_to("Edit", edit_admin_discipline_path(d), class: "btn btn-sm btn-outline-secondary"),
          button_to("Delete", admin_discipline_path(d), method: :delete,
            class: "btn btn-sm btn-outline-danger",
            form: { data: { turbo_confirm: "Delete #{d.name}? This will remove all associated ranks and promotions." } })
        ])
      end
    end
    render(t)
  end

  def discipline_ranks_table(ranks, discipline)
    t = TableComponent.new(rows: ranks)
    t.with_column("Position") { |r| r.position }
    t.with_column("Name") { |r| r.name }
    t.with_column("", html_class: "text-end") do |r|
      content_tag(:div, class: "d-flex gap-1 justify-content-end") do
        safe_join([
          link_to("Edit", edit_admin_discipline_rank_path(discipline, r), class: "btn btn-sm btn-outline-secondary"),
          button_to("Delete", admin_discipline_rank_path(discipline, r), method: :delete,
            class: "btn btn-sm btn-outline-danger",
            form: { data: { turbo_confirm: "Delete #{r.name}?" } })
        ])
      end
    end
    render(t)
  end
end
