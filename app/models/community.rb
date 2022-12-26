class Community < ApplicationRecord
  extend FriendlyId
  belongs_to :account
  validates_presence_of :url, :name, :rules, :category
  has_many :posts, dependent: :destroy
  has_many :subscriptions
  has_many :subscribers, through: :subscriptions, source: :account
  has_one_attached :profile_image
  has_one_attached :cover_image

    CATEGORIES = Category.pluck(:name)

    friendly_id :name ,use: %i[slugged history] 
  
    def should_generate_new_friendly_id?
      name_changed? || slug.blank?
    end
end
