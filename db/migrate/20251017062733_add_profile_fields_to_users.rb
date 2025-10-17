# db/migrate/..._add_profile_fields_to_users.rb
class AddProfileFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :email, :string
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :height_cm, :integer
    add_column :users, :weight_kg, :float
    add_column :users, :date_of_birth, :date
    add_column :users, :daily_calories_goal, :integer
    add_column :users, :daily_protein_goal_g, :integer
    add_column :users, :daily_fats_goal_g, :integer

    # It's also good to add the indexes we missed
    add_index :users, :email, unique: true
    add_index :users, :uid
  end
end