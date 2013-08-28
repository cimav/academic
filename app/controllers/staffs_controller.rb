class StaffsController < ApplicationController
  #load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def schedule_table
    @include_js =  ["jquery.ui.datepicker","jquery.ui.datepicker-es","staffs"]

    @screen="schedule_table"
    @staff = Staff.find(current_user.id)

    @is_pdf = false
    @id     = params[:staff_id]
    
    @date   = Date.today.strftime("%Y-%m-%d")

    @tcs  = TermCourseSchedule.joins(:term_course=>:term).where("terms.status in (1,2,3) AND term_course_schedules.status=:status AND term_course_schedules.staff_id=:id AND (terms.start_date<=:date AND terms.end_date>=:date)",{:status=>1,:id=>@staff.id,:date=>@date})

    @sd = @tcs.minimum(:start_date)
    @ed = @tcs.maximum(:end_date)

    @schedule = Hash.new
    (4..22).each do |i|
      @schedule[i] = Array.new
      (1..7).each do |j|
        @schedule[i][j] = Array.new
      end
    end

    n = 0
    courses = Hash.new
    @min_hour = 24
    @max_hour = 1

    @tcs.each do |session_item|
      hstart    = session_item.start_hour.hour
      hend      = session_item.end_hour.hour - 1

      (hstart..hend).each do |h|
        if courses[session_item.term_course.course.id].nil?
          n += 1
          courses[session_item.term_course.course.id] = n
        end

        comments = ""
        if session_item.start_date != session_item.term_course.term.start_date
          comments += "Inicia: #{l session_item.start_date, :format => :long}\n"
        end

        if session_item.end_date != session_item.term_course.term.end_date
          comments += "Finaliza: #{l session_item.end_date, :format => :long}"
        end

        staff_name = session_item.staff.full_name rescue 'Sin docente'

        details = {
          "name"           => session_item.term_course.course.name,
          "staff_name" => staff_name,
          "classroom"  => session_item.classroom.name,
          "comments"   => comments,
          "id"         => session_item.id,
          "n"          => courses[session_item.term_course.course.id]
       }

        @schedule[h][session_item.day] << details
        @min_hour = h if h < @min_hour
        @max_hour = h if h > @max_hour
      end
    end

    respond_with do |format|
      format.html do
        render :layout => true
      end

      format.pdf do
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        html = render_to_string(:layout => false , :action => "schedule_table.html.haml")
        kit = PDFKit.new(html, :page_size => 'Letter')
        kit.stylesheets << "#{Rails.root}#{Academic::Application::ASSETS_PATH}pdf.css"
        filename = "horario-#{@tcs[0].staff.id}-#{@tcs[0].term_course.term.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end

  end

  def students
    @include_js =  ["jquery.ui.datepicker","jquery.ui.datepicker-es","staffs"]

    @screen="students"
    @staff = Staff.find(current_user.id)
  end
 
  def student_files
    @student_advances_files = StudentAdvancesFiles.where(:term_student_id=>params[:id])
    @screen="students"
    @staff = Staff.find(current_user.id)
    render :layout => false
  end

  def student_file
    sf = StudentAdvancesFiles.find(params[:id]).file
    send_file sf.to_s, :x_sendfile=>true
  end 

  def grades
    @screen = "grades"
    @staff  = Staff.find(current_user.id)
    @today  = Date.today - 30

    @tc     = TermCourse.joins(:term).where("term_courses.staff_id=? AND terms.status in (1,2,3) AND terms.start_date <= ? AND terms.end_date >= ?", @staff.id, @today, @today)

    respond_with do |format|
      format.html do
        render :layout => true
      end
    end
  end

  def get_grades
    @include_js =  ["staffs"]
    @screen = "grades"
    @staff = Staff.find(current_user.id)
    @tc_id = params[:tc_id] 
    @today  = Date.today - 30
 
    ## r is from relationship
    @tc_r     = TermCourse.joins(:term).where("term_courses.id=? AND terms.status = 3 AND terms.start_date <= ? AND terms.end_date >= ?", @tc_id, @today, @today)
    @tc = @tc_r[0]

    if @tc_r.size > 0
      @tcs = TermCourseStudent.where(:term_course_id=>@tc_id)
    end
  end 

  def set_grades
    parameters = {}
    errors_counter = 0
    errors_array = Array.new
    counter = 0
    @staff = Staff.find(current_user.id)
    @tcs_id = params["tcs_id_#{counter}"]
    @grade = params["grade_#{counter}"]
    @today  = Date.today - 30

    while @tcs_id != nil  do
      tcs = TermCourseStudent.find(@tcs_id)
      @term = Term.where("id=? AND status=3 AND start_date<=? AND end_date >= ?", tcs.term_course.term.id, @today, @today)

      ## If term is not activate
      if @term.size > 0
        if !@grade.nil?
          tcs.grade= @grade
          if !tcs.save
            errors_counter= errors_counter + 1
            errors_array.push("Error al guardar la calificacion con id = #{@tcs_id}")
          end  
        end
      else
        errors_counter= errors_counter + 1
        errors_array.push("La calificacion no esta lista para ser guardada")
      end 
      
      counter = counter + 1
      @tcs_id  = params["tcs_id_#{counter}"]
      @grade   = params["grade_#{counter}"]
    end


    if errors_counter > 0
      render_error @staff,"Error",parameters,errors_array
    else
      render_message @staff,"Calificaciones guardadas correctamente",parameters
    end


  end

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


end
