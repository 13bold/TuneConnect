class CreateBuilds < ActiveRecord::Migration
  def self.up
    create_table :builds do |t|
      t.column :title, :string
      t.column :platform, :string
      t.column :component, :string
      t.column :version, :string
      t.column :build_number, :string
      t.column :status, :string
      t.column :file, :string
      t.column :icon_file, :string
      t.column :changelog, :string
      t.column :requirements, :string
    end
  end

  def self.down
    drop_table :builds
  end
end
