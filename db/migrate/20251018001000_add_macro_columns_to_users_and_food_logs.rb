class AddMacroColumnsToUsersAndFoodLogs < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.integer :daily_carbs_goal_g unless column_exists?(:users, :daily_carbs_goal_g)
      t.string :sex unless column_exists?(:users, :sex)
      t.integer :activity_level, default: 1, null: false unless column_exists?(:users, :activity_level)
      t.string :goal_type, default: "maintain", null: false unless column_exists?(:users, :goal_type)
      t.boolean :survey_completed, default: false, null: false unless column_exists?(:users, :survey_completed)
    end

    change_table :food_logs, bulk: true do |t|
      t.integer :carbs_g unless column_exists?(:food_logs, :carbs_g)
    end

    add_index :food_logs, :created_at unless index_exists?(:food_logs, :created_at)
  end
end
