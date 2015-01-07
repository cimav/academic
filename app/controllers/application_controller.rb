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

  helper_method :current_user
  
  def render_error(object,message,parameters,errors)
    if errors.nil?
      errors = object.errors
    end
   
    flash = {}
    flash[:error] = message
    respond_with do |format|
      format.html do
        if request.xhr?
          json = {}
          json[:flash] = flash
          json[:errors] = errors
          json[:errors_full] = object.errors.full_messages
          json[:params] = parameters
          render :json => json, :status => :unprocessable_entity
        else
          redirect_to object
        end
      end
    end
  end

  def render_message(object,message,parameters)
    flash = {}
    flash[:notice] = message
    respond_with do |format|
      format.html do
        if request.xhr?
          json = {}
          json[:flash] = flash
          json[:uniq]  = object.id
          json[:params] = parameters
          render :json => json
        else
          redirect_to object
        end
      end
    end
  end

  private
  def current_user
    @current_user ||= Staff.find(session[:user_id]) if session[:user_id]
  end
end
