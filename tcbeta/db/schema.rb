# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 6) do

  create_table "bugs", :force => true do |t|
    t.column "name",        :string
    t.column "description", :string
    t.column "user_id",     :integer
    t.column "status",      :string
  end

  create_table "builds", :force => true do |t|
    t.column "title",        :string
    t.column "platform",     :string
    t.column "component",    :string
    t.column "version",      :string
    t.column "build_number", :string
    t.column "status",       :string
    t.column "file",         :string
    t.column "icon_file",    :string
    t.column "changelog",    :string
    t.column "requirements", :string
  end

  create_table "feature_requests", :force => true do |t|
    t.column "name",        :string
    t.column "description", :string
    t.column "user_id",     :integer
    t.column "status",      :string
  end

  create_table "feedbacks", :force => true do |t|
    t.column "name",    :string
    t.column "user_id", :integer
    t.column "type",    :string
    t.column "content", :string
  end

  create_table "posts", :force => true do |t|
    t.column "name",      :string
    t.column "user_id",   :string
    t.column "content",   :string
    t.column "published", :boolean
  end

  create_table "users", :force => true do |t|
    t.column "email",        :string
    t.column "password",     :string
    t.column "display_name", :string
    t.column "first_login",  :boolean
  end

end