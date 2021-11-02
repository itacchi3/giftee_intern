class CreateUserScores < ActiveRecord::Migration[6.0]
  def change
    create_table :user_scores do |t|
      t.string :user_id, null: false
      t.string :group_id, null: false
      t.integer :set_id, null: false
      t.integer :score, null: false

      t.timestamps
    end
  end
end
