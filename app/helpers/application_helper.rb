module ApplicationHelper
  def next_direction_for_sort(current_sort, current_direction, column)
    if current_sort == column
      current_direction == "asc" ? "desc" : "asc"
    else
      "desc"
    end
  end

  def history_sort_link(label, column, current_sort, current_direction)
    dir = next_direction_for_sort(current_sort, current_direction, column)
    indicator = if current_sort == column
      current_direction == "asc" ? " ▲" : " ▼"
    else
      ""
    end
    link_to(label + indicator, food_logs_path(sort: column, direction: dir))
  end
end
