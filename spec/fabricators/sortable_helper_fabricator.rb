if !defined?(SortableHelper)
  class SortableHelper; end
end
Fabricator(:sortable_helper) do
  name { sequence(:name) { |i| "leet_sortable_#{i}" } }
  list_scope_id { (1..3).to_a.sample }
end