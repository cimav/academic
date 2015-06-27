class StaffsController < ApplicationController
  #load_and_authorize_resource
  #before_filter :auth_required
  before_filter :auth_required, :except=>[:get_advance_grades_token,:set_advance_grades_token,:get_advance_file_token]
  #http_basic_authenticate_with name: "dhh", password: "secret", only: :get_advance_grades_token

  respond_to :html, :xml, :json

  def schedule_table
    @include_js =  ["jquery.ui.datepicker","jquery.ui.datepicker-es","staffs"]

    @screen="schedule_table"
    @staff = Staff.find(current_user.id)

    @is_pdf = false
    @id     = params[:staff_id]
    
    @date   = (Date.today+20).strftime("%Y-%m-%d")

    @tcs  = TermCourseSchedule.joins(:term_course=>:term).where("terms.status in (1,2,3) AND term_course_schedules.status=:status AND term_course_schedules.staff_id=:id AND (terms.start_date<=:date AND terms.end_date>=:date)",{:status=>1,:id=>@staff.id,:date=>@date})

    @sd = @tcs.minimum(:start_date) || Date.today
    @ed = @tcs.maximum(:end_date)   || Date.today

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
          "name"         => session_item.term_course.course.name,
          "staff_name"   => staff_name,
          "classroom"    => session_item.classroom.name,
          "tc_id"       => session_item.term_course_id,
          "comments"     => comments,
          "id"           => session_item.id,
          "n"            => courses[session_item.term_course.course.id]
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
    if !@student_advances_files.size.eql? 0
      saf = @student_advances_files[0]
      if !saf.nil? 
        ts = TermStudent.find(saf.term_student_id)
        t  = ts.term
        advances = Advance.where("advances.student_id=? AND advances.status='C' AND advances.advance_date between ? and ?",ts.student.id,t.start_date,t.end_date).order("advance_date")
        @advance = advances[0]
        @avg     = get_adv_avg(@advance)
      end
    end
    @screen = "students"
    @staff  = Staff.find(current_user.id)
    render :layout => false
  end

  def student_file
    sf = StudentAdvancesFiles.find(params[:id]).file
    send_file sf.to_s, :x_sendfile=>true
  end 

  def grades
    @include_js =  ["grades"]
    @screen = "grades"
    @staff  = Staff.find(current_user.id)
    @today  = Date.today

    @tc     = TermCourse.joins(:term).where("term_courses.staff_id=? AND terms.status in (1,2,3) AND terms.start_date <= ? AND terms.end_date >= ?", @staff.id, @today, @today)

    @advances = Advance.joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("(curdate() between terms.grade_start_date and terms.grade_end_date) AND (advances.advance_date between terms.start_date and terms.end_date) AND programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id)",:id=>@staff.id,:level=>[1,2])

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
    @today  = Date.today
 
    ## r is from relationship
    @tc_r     = TermCourse.joins(:term).where("term_courses.id=? AND terms.status = 3 AND terms.start_date <= ? AND terms.end_date >= ?", @tc_id, @today, @today)
    @tc = @tc_r[0]

    if @tc_r.size > 0
      @tcs = TermCourseStudent.where(:term_course_id=>@tc_id,:status=>1)
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
    @today  = Date.today

    while @tcs_id != nil  do
      tcs = TermCourseStudent.find(@tcs_id)
      @term = Term.where("id=? AND terms.status=3 AND terms.start_date<=? AND terms.end_date >= ?", tcs.term_course.term.id, @today, @today)

      ## If term is not activate
      if @term.size > 0
        if !@grade.nil?
          tcs.grade= @grade
          if !tcs.save
            errors_counter= errors_counter + 1
            errors_array.push("Error al guardar la calificacion con id = #{@tcs_id}")
          else
            GradesLog.new({:staff_id=>@staff.id, :term_course_student_id=>tcs.id}).save
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

  def get_advance_file_token
    @token     = Token.where(:token=>params[:token]).where("DATE_ADD(CURDATE(), INTERVAL 1 DAY) between created_at AND expires")
    if @token[0].nil?
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end

    a  = Advance.find(params[:id])
    ts = a.student.term_students.last
    sf = StudentAdvancesFiles.where(:term_student_id=>ts.id).last
    
    sf = StudentAdvancesFiles.find(sf.id).file
    send_file sf.to_s, :x_sendfile=>true
  end


  def get_advance_grades_token
    @include_js = ["grades"]
    @access     = false
    @token      = Token.where(:token=>params[:token])
    if @token[0].nil?
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end
    
    @staff      = Staff.find(@token[0].attachable_id)
    @advance    = Advance.find(params[:id])

    @advances    = Advance.where(:student_id=>@advance.student_id, :status=>'C').order("advance_date")
    
    if @staff.id.to_i.eql? @advance.tutor1.to_i
      if !@advance.grade1_status.eql? 1
        @access = true
      end
    elsif @staff.id.to_i.eql? @advance.tutor2.to_i
      if !@advance.grade2_status.eql? 1
        @access = true
      end
    elsif @staff.id.to_i.eql? @advance.tutor3.to_i
      if !@advance.grade3_status.eql? 1
        @access = true
      end
    elsif @staff.id.to_i.eql? @advance.tutor4.to_i
      if !@advance.grade4_status.eql? 1
        @access = true
      end
    elsif @staff.id.to_i.eql? @advance.tutor5.to_i
      if !@advance.grade5_status.eql? 1
        @access = true
      end
    end

    if !@access
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end

    render :layout => 'standalone'
  end
  
  def get_advance_grades
    @include_js = ["grades"] 
    @screen     = "grades"
    @access     = false
    
    @staff      = Staff.find(current_user.id)
    @advance    = Advance.find(params[:id])
    
    @advances    = Advance.where(:student_id=>@advance.student_id, :status=>'C').order("advance_date")

    if @staff.id.to_i.eql? @advance.tutor1.to_i
      @access = true
    elsif @staff.id.to_i.eql? @advance.tutor2.to_i
      @access = true
    elsif @staff.id.to_i.eql? @advance.tutor3.to_i
      @access = true
    elsif @staff.id.to_i.eql? @advance.tutor4.to_i
      @access = true
    elsif @staff.id.to_i.eql? @advance.tutor5.to_i
      @access = true
    end
  end
  
  def set_advance_grades_token
    parameters = {}
    errors_counter = 0
    errors_array = Array.new
    counter = 0
    @advance = Advance.find(params[:id])
    @token   = Token.where(:token=>params[:token])
    @staff   = Staff.find(@token[0].attachable_id)
    if @advance.tutor1.to_i.eql? @staff.id
      @advance.grade1        = params[:grade_s].to_i
      @advance.grade1_status = 1
    elsif @advance.tutor2.to_i.eql? @staff.id
      @advance.grade2        = params[:grade_s].to_i
      @advance.grade2_status = 1
    elsif @advance.tutor3.to_i.eql? @staff.id
      @advance.grade3        = params[:grade_s].to_i
      @advance.grade3_status = 1
    elsif @advance.tutor4.to_i.eql? @staff.id
      @advance.grade4        = params[:grade_s].to_i
      @advance.grade4_status = 1
    elsif @advance.tutor5.to_i.eql? @staff.id
      @advance.grade5        = params[:grade_s].to_i
      @advance.grade5_status = 1
    end
    
    if @advance.notes.blank?
      @advance.notes = params[:comments]
    else
      @advance.notes = "#{@advance.notes}\n#{params[:comments]}"
    end
    
    if @advance.save
      render_message @advance,"Calificaciones guardadas correctamente",parameters
    else
      render_error @advance,"Error al guardar calificaciones",parameters,errors_array
    end
  end

  def set_advance_grades
    parameters = {}
    errors_counter = 0
    errors_array = Array.new
    counter = 0
    @advance = Advance.find(params[:id])
    @staff   = Staff.find(current_user.id)

    if @advance.tutor1.to_i.eql? @staff.id
      @advance.grade1        = params[:grade_s].to_i
      @advance.grade1_status = 1
    elsif @advance.tutor2.to_i.eql? @staff.id
      @advance.grade2        = params[:grade_s].to_i
      @advance.grade2_status = 1
    elsif @advance.tutor3.to_i.eql? @staff.id
      @advance.grade3        = params[:grade_s].to_i
      @advance.grade3_status = 1
    elsif @advance.tutor4.to_i.eql? @staff.id
      @advance.grade4        = params[:grade_s].to_i
      @advance.grade4_status = 1
    elsif @advance.tutor5.to_i.eql? @staff.id
      @advance.grade5        = params[:grade_s].to_i
      @advance.grade5_status = 1
    end

    if @advance.notes.blank?
      @advance.notes = params[:comments]
    else
      @advance.notes = "#{@advance.notes}\n#{params[:comments]}"
    end

    if @advance.save
      render_message @advance,"Calificaciones guardadas correctamente",parameters
    else
      render_error @advance,"Error al guardar calificaciones",parameters,errors_array
    end
  end

  def show_classroom_students
    @staff   = Staff.find(current_user.id)
    @tc      = TermCourse.find(params[:tc_id])
    @screen  = "schedule_table"
  end

  def enrollments
    @include_js =  ["enrollments"]
    @screen   = "enrollments"
    @staff    = Staff.find(current_user.id)
    ## Estudiantes con estatus de preinscrito
    #@students = Student.where(supervisor: @staff.id, status: Student::PENROLLMENT)
    @students = Student.where(supervisor: @staff.id, status: [1,6])
  end

  def get_adv_avg(a)
    grades = 0
    sum    = 0
    if !a.tutor1.nil?
      if !a.grade1.nil?
         sum = sum + a.grade1
         grades = grades + 1
      end
    end
    if !a.tutor2.nil?
      if !a.grade2.nil?
         sum = sum + a.grade2
         grades = grades + 1
      end
    end
    if !a.tutor3.nil?
      if !a.grade3.nil?
         sum = sum + a.grade3
         grades = grades + 1
      end
    end
    if !a.tutor4.nil?
      if !a.grade4.nil?
         sum = sum + a.grade4
         grades = grades + 1
      end
    end
    if !a.tutor5.nil?
      if !a.grade5.nil?
         sum = sum + a.grade5
         grades = grades + 1
      end
    end

    if !grades.eql? 0
      return sum / grades
    else
      return nil
    end
  end

end
