class CreateGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :groups do |t|
      t.string :group_id
      t.boolean :is_measurement_period

      t.timestamps
    end
  end
end
