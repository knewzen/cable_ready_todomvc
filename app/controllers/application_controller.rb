require "securerandom"

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :user_id

  before_action do
    cookies.signed[:user_id] ||= { value: SecureRandom.uuid, expires: 1.year.from_now }
  end

  def user_id
    cookies.signed[:user_id]
  end
end
