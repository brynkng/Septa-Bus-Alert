class AddShapes < ActiveRecord::Migration
  def up
    create_table :shapes do |t|
      t.string "shape_id" #shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence
      t.decimal "shape_pt_lat"
      t.decimal "shape_pt_lon"
      t.integer "shape_pt_sequence"
      t.timestamps
      t.string "route_id"
    end

    add_index :shapes, :shape_id
  end

  def down
  end
end
