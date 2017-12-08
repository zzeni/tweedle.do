class User < ApplicationRecord
  has_many :tweets, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :avatar,
                    styles: { medium: "300x300#", thumb: "100x100#" },
                    default_url: ":style/missing.png"

  validates_attachment :avatar,
                       content_type: { content_type: "image/jpeg" },
                       size: { in: 0..2.megabytes }

  # fake the Devise::Trackable IP properties, in order to omit them in the users table
  attr_accessor :current_sign_in_ip, :last_sign_in_ip
end
