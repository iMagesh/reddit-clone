class Account < ApplicationRecord
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable

  has_many :subscriptions
  has_many :communities ,through: :subscriptions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :save_posts
  has_one_attached :profile_image, dependent: :destroy
  has_many :banned_users

  validates_presence_of :first_name, :last_name, :username
  validates :username, uniqueness: true
  def full_name
    "#{first_name} #{last_name}"
  end

  def upvoted_post_ids
    self.votes.where(upvote: true).pluck(:post_id)
  end

  def downvoted_post_ids
    self.votes.where(upvote: false).pluck(:post_id)
  end
  
end
