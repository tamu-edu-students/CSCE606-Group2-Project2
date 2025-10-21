class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, index: { unique: true } # Index for fast lookup and uniqueness
      t.string :provider
      t.string :uid, index: true # Index for fast lookup

      t.integer :height_cm
      t.float :weight_kg
      t.date :date_of_birth

      t.integer :daily_calories_goal
      t.integer :daily_protein_goal_g
      t.integer :daily_fats_goal_g
      t.integer :daily_carbs_goal_g

      t.timestamps
    end
  end
end
