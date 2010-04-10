class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.column :name, :string
      t.column :user_id, :string
      t.column :content, :string
      t.column :published, :boolean
    end
  end

  def self.down
    drop_table :posts
  end
end
