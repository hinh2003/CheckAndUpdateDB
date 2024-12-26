# frozen_string_literal: true

# this is User model
class User < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  validates(:email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true)
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true


end
