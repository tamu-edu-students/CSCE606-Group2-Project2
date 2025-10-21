class CreateFoodLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :food_logs do |t|
      # This creates the user_id column and adds a foreign key constraint
      t.references :user, null: false, foreign_key: true

      t.string :food_name
      t.integer :calories
      t.integer :protein_g
      t.integer :fats_g
      t.integer :carbs_g
      t.string :image_url # For the image analysis feature

      t.timestamps
    end
    add_index :food_logs, :created_at
  end
end
