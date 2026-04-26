module Admin::SchedulesHelper
  def schedule_sort_link(col, label, location, schedule, sort:, direction:, q: nil, day: nil)
    new_dir = (sort == col && direction == "asc") ? "desc" : "asc"
    icon    = sort == col ? (direction == "asc" ? "bi-sort-up" : "bi-sort-down") : "bi-arrow-down-up text-muted"
    url     = admin_location_schedule_path(location, schedule, sort: col, direction: new_dir, q: q, day: day)
    link_to(url, class: "text-decoration-none text-reset d-inline-flex align-items-center gap-1") do
      safe_join([label, content_tag(:i, "", class: "bi #{icon} small")])
    end
  end
end
