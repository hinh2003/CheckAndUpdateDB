# frozen_string_literal: true

# The User model represents a user in the application.
# It is responsible for handling user authentication, registration,
# profile management, and other user-related functionality.
# This model is associated with several other models like `Post`, `Relationship`,
# and more. It uses features like secure password authentication and
# token generation for password resets.
module SessionHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def current_user
    if (user_id = session[:user_id])
      User.find_by(id: user_id)
    elsif (user_id = cookies.encrypted[:user_id])
      user = User.find_by(id: user_id)
      if user&.authenticated?(:remember, cookies[:remember_token])
        log_in user
        user
      end
    end
  end

  def current_user?(user)
    user && user == current_user
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    forget(current_user)
    session.delete(:user_id)
  end

  def forget(user)
    cookies.delete(:user_id)
  end

  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end
end
