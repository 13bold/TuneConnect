class CreateFeedbacks < ActiveRecord::Migration
  def self.up
    create_table :feedbacks do |t|
      t.column :name, :string
      t.column :user_id, :integer
      t.column :type, :string
      t.column :content, :string
    end
  end

  def self.down
    drop_table :feedbacks
  end
end
