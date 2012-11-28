class StudentAdvancesFileMessagesController < ApplicationController
  before_filter :auth_required
  respond_to :html, :json 
  def show

  end 


  def index
    @staff = Student.includes(:program).find(session[:user_id])
    @safms   = StudentAdvancesFileMessage.where(:student_advances_file_id=>params[:student_advances_file_id])
    @saf_id  = params[:student_advances_file_id]
    @safm = StudentAdvancesFileMessage.new
    render :layout=>false
  end

  def create
    flash = {}
    @staff = Staff.find(session[:user_id])
    @safm    = @staff.student_advances_file_message.create(params[:student_advances_file_message])
    
    if @staff.save
      flash[:notice]=params[:student_advances_file_message][:message]
      respond_with do |format|
        format.html do 
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:flash][:id] = @safm.id
            render :json => json
          else
            redirect_to :action => 'index'
          end
        end
      end
    else
      flash[:error]="Error al enviar el mensaje"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @staff.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to :action => 'index'
          end
        end
      end
    end
  end

  def destroy
    @safm = StudentAdvancesFileMessage.find(params[:id])
    if @safm.destroy
      flash[:notice]="Mensaje eliminado"
      respond_with do |format|
        format.html do 
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to :action => 'index'
          end
        end
      end
    else
      flash[:error]="Error al eliminar el mensaje"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @safm.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to :action => 'index'
          end
        end
      end
    end
  end
end
