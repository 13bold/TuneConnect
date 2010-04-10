class User < ActiveRecord::Base
  has_many :bugs
  has_many :feature_requests
  has_many :feedbacks
  has_many :posts
end
