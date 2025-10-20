# frozen_string_literal: true

class AddConfirmableToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add confirmable columns only if they don't already exist
    unless column_exists?(:users, :confirmation_token)
      add_column :users, :confirmation_token, :string
    end

    unless column_exists?(:users, :confirmed_at)
      add_column :users, :confirmed_at, :datetime
    end

    unless column_exists?(:users, :confirmation_sent_at)
      add_column :users, :confirmation_sent_at, :datetime
    end

    # unconfirmed_email is used when using reconfirmable
    unless column_exists?(:users, :unconfirmed_email)
      add_column :users, :unconfirmed_email, :string
    end

    add_index :users, :confirmation_token, unique: true unless index_exists?(:users, :confirmation_token)
  end
end
