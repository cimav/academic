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

      user = Staff.where("(email = ? ) AND status = ?",session[:user_email], Staff::ACTIVE).first || User.where(:email => session[:user_email], :access => User::MANAGER).first
      is_admin?(user.email) #set user as administrator
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

  def get_month_name(number)
    months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
    name = months[number - 1]
    return name
  end

  def is_admin?(email)
    if User.where(:email => email, :access => User::MANAGER).first
      session[:is_admin] = true
    end
  end
  helper_method :is_admin?

  def set_current_user
    if session[:is_admin]
      staff = Staff.find(params[:id])
      email = staff.email
      @current_user = Staff.where(:email => email).first
      session[:user_email] = email
      session[:user_auth]  = nil
      puts "Ahora es: #{@current_user.full_name}"
      puts session[:user_email].to_s
      puts session[:user_id].to_s

    else
      puts "No tiene permisos para esa acción"
    end
    redirect_to root_path
  end
  helper_method :set_current_user

  private
  def current_user
    @current_user ||= Staff.find(session[:user_id]) if session[:user_id]
  end




end
