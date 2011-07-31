require 'spec_helper'

module MongoMapper::Plugins
  describe SortableItem do
    after do
      SortableHelper.sortable_item_options = { :list_scope => nil }
    end
    
    describe "plugin .included magic" do
      it "sets a new mongo key of :position on the document" do
        the_position_key = SortableHelper.keys["position"]
        the_position_key.should_not be_nil
        
        the_position_key.type.should == Integer
      end
      it "provides a new scope named .in_order" do
        SortableHelper.scopes.keys.should include(:in_order)
      end
      it "sets up a class_accessor called .sortable_item_options" do
        SortableHelper.sortable_item_options.should == { :list_scope => nil }
      end
      
      describe "default callbacks" do
        it "sets up a before_create callback to ensure the item gets added to the list" do
          the_callbacks = SortableHelper._create_callbacks
          the_callbacks.find { |cb| cb.kind == :before && cb.filter == :add_to_list_bottom }.
            should_not be_nil
        end
        it "adds new items to the bottom of the list by default" do
          3.times { Fabricate(:sortable_helper) }
          new_item = Fabricate(:sortable_helper)
          new_item.position.should == 4
        end
        context "with already-ordered items" do
          it "doesn't change the position" do
            (1..3).to_a.each { |i| Fabricate(:sortable_helper, :position => i + 1) }
            new_item = Fabricate(:sortable_helper, :position => 1)
            new_item.reload
            new_item.position.should == 1
            SortableHelper.in_order.first.should == new_item
          end
        end
        it "sets up a before_destroy callback to ensure the item gets removed from the list" do
          the_callbacks = SortableHelper._destroy_callbacks
          the_callbacks.find { |cb| cb.kind == :before && cb.filter == :decrement_positions_on_lower_items }.
            should_not be_nil
        end
        it "gracefully removes an item from the list, leaving it in proper order on destroy" do
          (1..3).to_a.each { |i| Fabricate(:sortable_helper, :position => i) }
          SortableHelper.in_order.first.destroy
          SortableHelper.in_order.all.map { |sh| sh.position }.should == [1, 2]
        end
      end
    end
    
    describe ".list_scope_column=" do
      it "allows you to give it a column name that will be saved into the options" do
        SortableHelper.list_scope_column = :list_scope_id
        SortableHelper.sortable_item_options.should == { :list_scope => :list_scope_id }
      end
    end
    
    describe ".list_scope_column" do
      it "returns the defined list_scope_column" do
        SortableHelper.list_scope_column = :list_scope_id
        SortableHelper.list_scope_column.should == :list_scope_id
      end
      it "returns nil by default" do
        SortableHelper.list_scope_column.should be_nil
      end
    end
    
    describe ".in_list" do
      it "returns a scope that... uh, scopes the list" do
        SortableHelper.in_list.should be_a_kind_of(Plucky::Query)
      end
      it "filters nothing by default (entire collection is the list)" do
        3.times { Fabricate(:sortable_helper) }
        recs = SortableHelper.in_list.in_order.all
        recs.size.should == 3
      end
      it "uses the :list_scope option to build the scope" do
        SortableHelper.list_scope_column = :list_scope_id
        SortableHelper.should_receive(:where).with({:list_scope_id => 3})
        SortableHelper.in_list(3)
      end
      it "correctly scopes the list, baby" do
        5.times { Fabricate(:sortable_helper, :list_scope_id => 1) }
        5.times { Fabricate(:sortable_helper, :list_scope_id => 2) }
        SortableHelper.list_scope_column = :list_scope_id
        
        SortableHelper.in_list(1).count.should == 5
        SortableHelper.in_list(2).count.should == 5
        SortableHelper.count.should == 10
      end
    end
    
    describe ".reorder" do
      it "updates the positions of the given ids based on their array order" do
        items = (1..3).to_a.map { |i| Fabricate(:sortable_helper, :position => i) }
        
        SortableHelper.reorder([items[2].id, items[0].id, items[1].id])
        new_list = SortableHelper.in_list.in_order.all
        new_list[0].should == items[2]
        new_list[1].should == items[0]
        new_list[2].should == items[1]
      end
    end
    
    describe "#in_list?" do
      it "returns false if the record doesn't have a numeric position" do
        sortable = Fabricate.build(:sortable_helper)
        sortable.stub!(:position).and_return(nil)
        sortable.position.should be_nil
        sortable.should_not be_in_list
      end
      it "returns true if the record has a numeric position" do
        sortable = Fabricate.build(:sortable_helper)
        sortable.position = 1
        sortable.should be_in_list
      end
    end
    
    describe "#scoped_list_id" do
      it "returns nil if there is no defined list scope" do
        Fabricate.build(:sortable_helper).scoped_list_id.should be_nil
      end
      it "returns the value of the given column" do
        SortableHelper.list_scope_column = :list_scope_id
        sortable = Fabricate.build(:sortable_helper)
        sortable.scoped_list_id.should == sortable.list_scope_id
      end
    end
    
    describe "#bottom_of_list" do
      before do
        SortableHelper.list_scope_column = :list_scope_id
        5.times { Fabricate(:sortable_helper, :list_scope_id => 1) }
        2.times { Fabricate(:sortable_helper, :list_scope_id => 2) }
      end
      it "returns the position that an item at the bottom of the list should have" do
        list_1 = Fabricate.build(:sortable_helper, :list_scope_id => 1)
        list_2 = Fabricate.build(:sortable_helper, :list_scope_id => 2)
        list_1.bottom_of_list.should == 6
        list_2.bottom_of_list.should == 3
      end
    end
    
    describe "#remove_from_list" do
      before do
        @list = (1..5).to_a.map { |i| Fabricate(:sortable_helper, :name => "Item #{i}") }
        @middle_item = @list[2]
      end
      it "sets the current position to nil" do
        @middle_item.remove_from_list
        @middle_item.position.should be_nil
      end
      it "pushes everything below the current item up a notch" do
        old_position = @middle_item.position
        @middle_item.remove_from_list
        item_3 = @list[3]
        item_3.reload
        item_3.position.should == old_position
        
        item_4 = @list[4]
        item_4.reload
        item_4.position.should == old_position + 1
      end
    end
    
    describe "#set_position" do
      it "sets the item to the new position" do
        item = Fabricate.build(:sortable_helper)
        item.set_position 5
        item.position.should == 5
      end
      it "moves everything below the given position down a notch" do
        list = (1..5).to_a.map { |i| Fabricate(:sortable_helper, :name => "Item #{i}") }
        item = Fabricate(:sortable_helper)
        item.set_position 3
        old_item_3 = SortableHelper.find(list[2].id)
        old_item_3.reload
        old_item_3.position.should == 4
      end
      it "inserts it correctly into the list" do
        list = (1..5).to_a.map { |i| Fabricate(:sortable_helper, :name => "Item #{i}") }
        item = Fabricate(:sortable_helper, :name => "The New Guy")
        item.set_position 3
        new_list = SortableHelper.in_list.in_order.all
        new_list[2].should == item
        new_list.map { |i| i.name + ": pos = " + i.position.to_s }.should == ["Item 1: pos = 1", "Item 2: pos = 2", "The New Guy: pos = 3", "Item 3: pos = 4", "Item 4: pos = 5", "Item 5: pos = 6"]
      end
    end
  
  end
end