class CreateGroupScoreCalcSets < ActiveRecord::Migration[6.0]
  def change
    create_table :group_score_calc_sets do |t|
      t.string :group_id, null: false
      t.integer :set_id, null: false, default: 0

      t.timestamps
    end
    add_index :group_score_calc_sets, [:group_id], unique: true
  end
end
