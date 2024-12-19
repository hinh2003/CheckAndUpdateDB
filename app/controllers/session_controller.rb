# frozen_string_literal: true

# this is SessionController
class SessionController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      process_authenticated_user(user)
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  private

  def process_authenticated_user(user)
    log_in user
    redirect_to new_action_input_path
  end
end
