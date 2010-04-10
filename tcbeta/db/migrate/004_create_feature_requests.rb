class CreateFeatureRequests < ActiveRecord::Migration
  def self.up
    create_table :feature_requests do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :user_id, :integer
      t.column :status, :string
    end
  end

  def self.down
    drop_table :feature_requests
  end
end
