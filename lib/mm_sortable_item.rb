require "mm_sortable_item/version"
require "mongo_mapper"

# An ActsAsList-ish plugin for MongoMapper, since this doesn't seem to exist in a well-tested form.
# Props to John Nunemaker for starting us down the right path here
module MongoMapper
  module Plugins
    module SortableItem
      extend ActiveSupport::Concern
  
      included do
        key :position, Integer
        scope :in_order, sort(:position)
        class_attribute :sortable_item_options
        self.sortable_item_options = { :list_scope => nil }
      
        # some callbacks we'll want
        before_create :add_to_list_bottom, :unless => :in_list?
        before_destroy :decrement_positions_on_lower_items
      end
  
      module ClassMethods
        def reorder(ids)
          ids.each_with_index do |id, index|
            set(id, :position => index + 1)
          end
        end
      
        def in_list list_id = nil
          where(conditions_for_list_scope(list_id))
        end
      
        def conditions_for_list_scope list_id
          the_query = {}        
          the_column = list_scope_column
          if the_column
            the_query = { the_column => list_id }
          end
          the_query
        end
      
        def list_scope_column= new_column
          self.sortable_item_options[:list_scope] = new_column
        end
      
        def list_scope_column
          self.sortable_item_options[:list_scope]
        end
      end

      module InstanceMethods
        def in_list?
          !send(:position).nil?
        end
      
        def scoped_list_id
          the_column = self.class.list_scope_column
          the_column ? self.send(the_column) : nil
        end
      
        def add_to_list_bottom
          add_to_list
        end
      
        def add_to_list_top
          add_to_list 1
        end
      
        def add_to_list position = bottom_of_list
          remove_from_list
          increment_positions_on_lower_items position
          set_position position
        end
      
        def bottom_of_list
          self.class.in_list( scoped_list_id ).count + 1
        end
      
        def lower_than_conditions position = self.position
          query = self.class.conditions_for_list_scope scoped_list_id
          query.merge( :position.gte => position )
        end
      
        def decrement_positions_on_lower_items position = self.position
          self.class.decrement( lower_than_conditions(position), { :position => 1 } )
        end
      
        def increment_positions_on_lower_items position = self.position
          self.class.increment( lower_than_conditions(position), { :position => 1 } )
        end
      
        def remove_from_list
          if in_list?
            decrement_positions_on_lower_items
            self.position = nil
          end
        end
      
        def set_position new_position
          remove_from_list
          increment_positions_on_lower_items new_position
          if new_position != self.position
            self.position = new_position
            save unless new_record?
          end
        end
      
      end
    end
  end
end
