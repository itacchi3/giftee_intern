class CreateGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :groups do |t|
      t.string :group_id, null: false
      t.boolean :is_measurement_period, null: false, default: false

      t.timestamps
    end
    add_index :groups, [:group_id], unique: true
  end
end
