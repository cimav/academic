class ApplicationController < ActionController::Base
  protect_from_forgery
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def authenticated?
    if session[:user_email].blank?
      return false
    end

    if session[:user_auth].blank?
      user = Staff.where("(email = ? ) AND status = ?",session[:user_email], Staff::ACTIVE).first

      session[:user_auth] = user && ( user.email == session[:user_email] || user.email_cimav == session[:user_email])
      if session[:user_auth]
        session[:user_id] = user.id
      end
    else
      session[:user_auth]
    end
  end
  helper_method :authenticated?

  def auth_required
    redirect_to '/login' unless authenticated?
  end
end
