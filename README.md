# mm\_sortable\_item

This is a quick little MongoMapper plugin that provides some basic acts-as-list style functionality on mongo documents. By default things are added to the list bottom.

## Usage

In the gemfile:

    gem 'mm_sortable_item'
    
In your model:

``` ruby
  class SortableDocument
    include MongoMapper::Document
    plugin MongoMapper::Plugins::SortableItem
    
    list_scope_column :parent_id # optional if you want to scope the lists
    
    # ...
  end
```

Then you have access to some helpful methods, such as:

* `.in_order` retrieves the list items in order
* `.in_list(id)` retrieves the items scoped as you wish
* `.reorder(orderd_array_of_ids)` sets the positions of the given ids in order
* `object.set_position(position)` inserts object into the list at the given position

## Credit

John Nunemaker for mongo_mapper itself, as well as a start down the road of how to implement this. It's definitely not as "fully functional" as `acts_as_list`, but it does everything I need :).

* Author: Matt Wilson (mwilson@agoragames.com)
* GitHub: http://github.com/hypomodern