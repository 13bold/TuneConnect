class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :email, :string
      t.column :password, :string
      t.column :display_name, :string
      t.column :first_login, :boolean
    end
  end

  def self.down
    drop_table :users
  end
end
