# db/migrate/..._add_profile_fields_to_users.rb
class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :sex
      t.integer :activity_level, default: 1, null: false
      t.string :goal_type, default: "maintain", null: false
      t.boolean :survey_completed, default: false, null: false
    end
  end
end
