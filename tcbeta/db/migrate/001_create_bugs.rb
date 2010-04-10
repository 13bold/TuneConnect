class CreateBugs < ActiveRecord::Migration
  def self.up
    create_table :bugs do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :user_id, :integer
      t.column :status, :string
    end
  end

  def self.down
    drop_table :bugs
  end
end
