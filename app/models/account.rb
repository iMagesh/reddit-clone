class Account < ApplicationRecord

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable

  has_many :subscriptions
  has_many :communities ,through: :subscriptions
  has_many :posts
  has_many :comments
  has_many :votes
  has_one_attached :profile_image
  has_many :banned_users

  validates_presence_of :first_name, :last_name, :username
  validates :username, uniqueness: true
  validates_format_of :first_name, :last_name,:multiline => true, :with => /^[a-z]+$/i
  validates_format_of :username, :multiline => true, :with => /^[a-z0-9]+$/i
  validate :acceptable_image

  def full_name
    "#{first_name} #{last_name}"
  end

  def upvoted_post_ids
    self.votes.where(upvote: true).pluck(:post_id)
  end

  def downvoted_post_ids
    self.votes.where(upvote: false).pluck(:post_id)
  end

  def acceptable_image
    return unless profile_image.attached?
    acceptable_types = ["image/jpeg", "image/png", "image/gif"]
    unless acceptable_types.include?(profile_image.content_type)
      errors.add(:profile_image, "must be a JPEG or PNG")
    end
  end

end
