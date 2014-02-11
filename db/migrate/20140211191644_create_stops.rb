class CreateStops < ActiveRecord::Migration
  def change
    create_table :stops do |t|
      t.integer :stop_id
      t.float :latitude
      t.float :longitude
      t.text :stop_name
      t.text :route

      t.timestamps
    end
  end
end
