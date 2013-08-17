class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.time :start_hour
      t.string :route
      t.text :direction
      t.float :start_latitude
      t.float :end_latitude
      t.float :start_longitude
      t.float :end_longitude
      t.boolean :is_weekday
      t.float :speed

      t.timestamps
    end
  end
end
