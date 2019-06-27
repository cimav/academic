# -*- coding: utf-8 -*-
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
    
    #@date   = (Date.today).strftime("%Y-%m-%d")

    #@tcs  = TermCourseSchedule.joins(:term_course=>:term).where("terms.status in (1,2,3) AND term_course_schedules.status=:status AND term_course_schedules.staff_id=:id AND (terms.start_date<=:date AND terms.end_date>=:date)",{:status=>1,:id=>@staff.id,:date=>@date})
    @tcs  = TermCourseSchedule.joins(:term_course=>:term).where("terms.status in (1,2,3) AND term_course_schedules.status=:status AND term_course_schedules.staff_id=:id",{:status=>1,:id=>@staff.id})

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
    @term_student =  TermStudent.find(params[:id])

    if params[:type].to_i.eql? 2
      @student_advances_files = StudentAdvancesFiles.where(:term_student_id=>params[:id],:student_advance_type=>3)
    elsif params[:type].to_i.eql? 1
      @student_advances_files = StudentAdvancesFiles.where(:term_student_id=>params[:id],:student_advance_type=>[1,2,3])
    else
      @student_advances_files = StudentAdvancesFiles.where(:term_student_id=>params[:id])
    end

    if !@student_advances_files.size.eql? 0
      saf = @student_advances_files[0]
      if !saf.nil? 
        ts = TermStudent.find(saf.term_student_id)
        t  = ts.term
        advances = Advance.where("advances.student_id=? AND advances.status='C' AND advances.advance_date between ? and ?",ts.student.id,t.start_date,t.end_date).order("advance_date")
        @advance = advances[0]
        if !@advance.nil?
          @avg     = get_adv_avg(@advance)
        end
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

    @tc     = TermCourse.joins(:term).where("term_courses.staff_id=? AND terms.status in (1,2,3) AND terms.grade_start_date <= ? AND terms.grade_end_date >= ?", @staff.id, @today, @today)

    #@advances = Advance.joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("(curdate() between terms.grade_start_date and terms.grade_end_date) AND (advances.advance_date between terms.start_date and terms.end_date) AND programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id and advance_type=1)",:id=>@staff.id,:level=>[1,2])
    @advances = Advance.select("distinct advances.*").joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("(curdate() between terms.grade_start_date and terms.grade_end_date) AND terms.status=3 AND programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id) and advances.status in (:status)",:id=>@staff.id,:level=>[1,2],:status=>['P']).where(:advance_type=>1)

    #@protocols = Advance.select("distinct advances.*").joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("(curdate() between terms.advance_start_date and terms.advance_end_date) AND terms.status in (1,2,3) AND (advances.advance_date between terms.start_date and terms.end_date) AND programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id) and advances.status in (:status)",:id=>@staff.id,:level=>[1,2],:status=>['P','C']).where(:advance_type=>2)
    @protocols = Advance.select("distinct advances.*").joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("(curdate() between terms.grade_start_date and terms.grade_end_date) AND terms.status in (1,2,3) AND programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id) and advances.status in (:status)",:id=>@staff.id,:level=>[1,2],:status=>['P','C']).where(:advance_type=>2)
    
   #@seminars = Advance.select("distinct advances.*").joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("(curdate() between terms.grade_start_date and terms.grade_end_date) AND programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id) AND advances.advance_type=3 AND advances.status in (:status) AND terms.status in (:t_status)",:id=>@staff.id,:level=>[1,2],:status=>['P','C'],:t_status=>[1,2,3]).where(:advance_type=>3)

@seminars = Advance.select("distinct advances.*").joins(:student=>:program).joins(:student=>{:term_students=>:term}).where("programs.level in (:level) AND (tutor1=:id OR tutor2=:id OR tutor3=:id OR tutor4=:id OR tutor5=:id) AND advances.advance_type=3 AND advances.status in (:status) AND terms.status in (:t_status)",:id=>@staff.id,:level=>[1,2],:status=>['P','C'],:t_status=>[1,2,3]).where(:advance_type=>3)

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
    @tc_r     = TermCourse.joins(:term).where("term_courses.id=? AND terms.status = 3 AND terms.grade_start_date <= ? AND terms.grade_end_date >= ?", @tc_id, @today, @today)
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
      @term = Term.where("id=? AND terms.status=3 AND terms.grade_start_date<=? AND terms.grade_end_date >= ?", tcs.term_course.term.id, @today, @today)

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
    @screen     = "grades"
    @access     = false
    
    @staff      = Staff.find(current_user.id)
    @advance    = Advance.find(params[:id])

    if @staff.nil?
      render text: "Permisos insuficientes"
      return
    end

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

    if @advance.advance_type.to_i.eql? Advance::PROTOCOL
      @include_js = ["protocol"] 
      @protocol   = Protocol.where(:advance_id=>@advance.id,:staff_id=>@staff.id)[0]
      @questions  = Question.where(:group=>1)
      render 'protocol'
      return
    elsif @advance.advance_type.to_i.eql? Advance::SEMINAR
      @include_js = ["seminar"] 
      @protocol   = Protocol.where(:advance_id=>@advance.id,:staff_id=>@staff.id)[0]
      @questions  = Question.where(:group=>2)
      render 'seminar'
      return
    end
    
    @include_js = ["grades"] 
 
    @advances    = Advance.where(:student_id=>@advance.student_id, :status=>'C').order("advance_date")

  end

  def save_protocol
    parameters   = {}
    errors_array = Array.new

    @protocol = Protocol.find(params[:protocol_id]) rescue nil
    @access   = true

    @advance  = Advance.find(params[:advance_id]) rescue Advance.find(@protocol.advance_id)
    @staff    = Staff.find(current_user.id)

    if @protocol.nil?
      @protocol            = Protocol.new
      @protocol.advance_id = @advance.id
      @protocol.staff_id   = @staff.id
      @protocol.status     = 3
    end

    if @advance.advance_type.eql? 2 # protocol
      @protocol.group      = 1
      @protocol.grade_status = params[:grade_status]
      parameters[:status]    = @protocol.status
    elsif @advance.advance_type.eql? 3 # seminar
      @protocol.group      = 2
    
      recomm = params[:grade_status]

      if recomm.to_i.eql? 1  ## con recomm
        @protocol.status       = 4
        @protocol.grade_status = 3
      end

=begin
      if params[:recom].to_i.eql? 1 ## yes recomm
        @protocol.status        = 4
        @access                 = false
      elsif params[:recom].to_i.eql? 2 ## no recomm
        @protocol.status       = 4
        @access                = false
      end
=end
    end
        
    if @protocol.save
      if @access
        @protocol.answers.destroy_all
        counter   = 0
        sum       = 0
        reprobate = false

        params.each do |p|
          if p[0].include? "question_id_"
            q_id = p[0].split("_")[2]
            textarea      = "text_area_#{q_id}"
            radiobutton   = "radio_button_#{q_id}"
            question_id   = "question_id_#{q_id}"

            question      = Question.find(params[question_id].to_i)
            question_type = question.question_type
          
            @answer = Answer.new
            @answer.question_id = q_id
            @answer.protocol_id = @protocol.id
            @answer.answer      = params[radiobutton]
            @answer.comments    = params[textarea]

            if @advance.advance_type.to_i.eql? 3 # seminar
              if question_type.to_i.eql? 3 # grade question type
                if question.order.to_i.eql? 4
                  if @answer.answer.to_i<70
                    reprobate = true
                  end#@answer.answer
                end#question.order

                sum = @answer.answer.to_i + sum
                counter = counter + 1
              end#params[question_type]
            end
 
            if @answer.save
              logger.info "TODO OK"
            else
              errors_array << "Error al crear respuestas"
            end ## answer.save
          end ## if p[0].include...
        end ## params.each do ...
        
        if @advance.advance_type.eql? 3 # seminar
          avg = sum/counter
 
          if !@protocol.status.to_i.eql? 4
            if reprobate
              @protocol.grade_status = 2
            else
              if avg>70
                @protocol.grade_status = 1
              else
                @protocol.grade_status = 2
              end
            end
          end#@protocol.status

          @protocol.grade = avg
          @protocol.save
        end

        create_protocol(@protocol,@staff,@advance)
      end

      address = @advance.student.email_cimav rescue @advance.student.email  ## estudiante
      if @advance.advance_type.eql? 2  #protocol
        send_email(@advance,1,address,parameters)
      elsif @advance.advance_type.eql? 3  #seminar
        seminar_quorum_review(@advance,@staff)
        send_email(@advance,2,address,parameters)
      end

      parameters[:status] = @protocol.status
      render_message @protocol,"Evaluación enviada",parameters
    else
      render_error @protocol,"Error al crear/editar protocolo",parameters,nil
    end
  end

  def recomm_protocol
    parameters = {}

    @protocol = Protocol.find(params[:protocol_id])
    
    if params[:recom].to_i.eql? 1
      @protocol.grade_status = 1
    elsif params[:recom].to_i.eql? 2
      @protocol.grade_status = 2
    end

    if @protocol.save
      staff = Staff.find(@protocol.staff_id)
      advance = Advance.find(@protocol.advance_id)
      create_protocol(@protocol,staff,advance)
      parameters[:grade_status] = @protocol.grade_status
      render_message @protocol,"Protocolo actualizado",parameters
    else
      render_error @protocol,"Error al editar protocolo",parameters,nil
    end
  end

  def seminar_quorum_review(advance,staff)
    total       = get_tutors_size(advance)
    approved    = advance.protocols.where(:grade_status=>1).size
    disapproved = advance.protocols.where(:grade_status=>2).size
    recommended = advance.protocols.where(:grade_status=>3).size
    params = {}

    if total.eql? approved
       ## seminario aprobado
       ## cambia status a completado
       advance.status = 'C'
       advance.save
       ## no manda correos
    elsif disapproved.eql? 1
      ## seminario no aprobado
      ## cambia estatus
      advance.status = 'C'
      advance.save
      ## manda correo al asistente de departamento, al interesado y al director de tesis
      stf = Staff.find(advance.student.supervisor.to_i) rescue nil
      params[:student_id] = advance.student_id

      if stf
        User.where(:status=>1).each do |u|
          areas =  (eval u.areas) rescue nil
          if !areas.nil?
            if stf.area_id.in? areas
              address = u.email
              send_email(advance,3,address,params) ## asistente
            end
          end
        end

        if !stf.email.blank?
          address = stf.email
          send_email(advance,3,address,params)  ## dir. tesis
        end
      end

      address = advance.student.email_cimav rescue advance.student.email  ## estudiante
      send_email(advance,3,address,params) ## estudiante
    elsif recommended.eql? 1
      params[:student_id] = advance.student_id
      ## seminario en recomendación
      ## no cambia estatus
      ## correo a los revisores, al interesado y al director de tesis
      if !advance.tutor1.nil?
         tutor = Staff.find(advance.tutor1.to_i) rescue nil
         tutor_email(advance,tutor)
      end
      
      if !advance.tutor2.nil?
         tutor = Staff.find(advance.tutor2.to_i) rescue nil
         tutor_email(advance,tutor)
      end
      
      if !advance.tutor3.nil?
         tutor = Staff.find(advance.tutor3.to_i) rescue nil
         tutor_email(advance,tutor)
      end
      
      if !advance.tutor4.nil?
         tutor = Staff.find(advance.tutor4.to_i) rescue nil
         tutor_email(advance,tutor)
      end
      
      if !advance.tutor5.nil?
         tutor = Staff.find(advance.tutor5.to_i) rescue nil
         tutor_email(advance,tutor)
      end

      director = Staff.find(advance.student.supervisor.to_i) rescue nil ## dir.tesis
      tutor_email(advance,director)

      address = advance.student.email_cimav rescue advance.student.email 
      send_email(advance,5,address,params) ## estudiante
    end
  end

  def get_tutors_size(advance)
    counter = 0
    if !advance.tutor1.nil?
      counter = counter + 1
    end
    if !advance.tutor2.nil?
      counter = counter + 1
    end
    if !advance.tutor3.nil?
      counter = counter + 1
    end
    if !advance.tutor4.nil?
      counter = counter + 1
    end
    if !advance.tutor5.nil?
      counter = counter + 1
    end
    return counter
  end

  def tutor_email(advance,tutor)
    params[:student_id] = advance.student_id
    if !tutor.nil?
      if !tutor.email.blank?
        address = tutor.email
        send_email(advance,4,address,params) 
      end
    end
  end

  def create_protocol(protocol,staff,advance)
    @r_root  = Rails.root.to_s
    @rectangles = true

    supervisor      = Staff.find(advance.student.supervisor) rescue nil
    supervisor_name = supervisor.full_name rescue "N.D"
    supervisor_area = supervisor.area.name rescue "N.D"

    created = "#{advance.created_at.day} de #{get_month_name(advance.created_at.month)} de #{advance.created_at.year}"

    
    filename  = "#{Settings.sapos_route}/private/files/students/#{advance.student.id}"

    if !File.directory?(filename) 
      FileUtils.mkdir_p filename
    end
 
    if advance.advance_type.eql? 2
      pdf_route = "#{filename}/protocol-#{advance.id}-#{staff.id}.pdf"
    elsif advance.advance_type.eql? 3
      if protocol.grade_status.eql? 3 # con recomendaciones
        pdf_route = "#{filename}/seminar-#{advance.id}-#{staff.id}-recom.pdf"
      else
        pdf_route = "#{filename}/seminar-#{advance.id}-#{staff.id}.pdf"
      end
    end

    if File.exist?(pdf_route)
      File.delete(pdf_route)
    end

    filename = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
    pdf      = Prawn::Document.new(:background => filename, :background_scale=>0.36, :margin=>[90,60,60,60] ) 

    pdf.font_families.update(
          "Montserrat" => { :bold        => Rails.root.join("private/fonts/montserrat/Montserrat-Bold.ttf"),
                            :italic      => Rails.root.join("private/fonts/montserrat/Montserrat-Italic.ttf"),
                            :bold_italic => Rails.root.join("private/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                            :normal      => Rails.root.join("private/fonts/montserrat/Montserrat-Regular.ttf") })
    pdf.font "Montserrat"
    pdf.font_size 11

    advance = Advance.find(protocol.advance_id)

    if advance.advance_type.eql? 2
      time = Time.now
      @consecutivo = get_consecutive(advance.student, time, Certificate::PROTOCOL)

      pdf.text "<b>Coordinación de estudios de Posgrado\nFormato P-MA-E-#{time.year}#{@consecutivo}</b>\nChihuahua, Chih., a #{time.day} de #{get_month_name(time.month)} de #{time.year}", :inline_format=>true, :align=>:right
     
      text = "\n\nEVALUACIÓN PROTOCOLOS\n\n"
      pdf.text text , :style=> :bold, :align=> :center
    elsif advance.advance_type.eql? 3
      @consecutivo = get_consecutive(advance.student, advance.created_at, Certificate::SEMINAR)

      pdf.text "<b>Coordinación de estudios de Posgrado\nFormato SEM-#{advance.created_at.year}-#{@consecutivo}</b>\nChihuahua, Chih., a #{protocol.created_at.day} de #{get_month_name(protocol.created_at.month)} de #{protocol.created_at.year}", :inline_format=>true, :align=>:right
      
      text = "\n\nSEMINARIO FINAL\n\n"
      pdf.text text , :style=> :bold, :align=> :center
    end

    size = pdf.font_size
    
    data = []
    data << ["Fecha de Evaluación:", created]
    data << ["Alumno:",advance.student.full_name]
    data << ["Director de Tesis:",supervisor_name]
    data << ["Departamento:",supervisor_area]
    data << ["Programa:",advance.student.program.name]
    data << ["Título de la Tesis:",advance.title]

    tabla = pdf.make_table(data,:width=>500,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center,:column_widths=>[150,350])
    tabla.draw
    
    pdf.move_down 10
 
    icon_empty = pdf.table_icon('fa-square-o')
    icon_ok    = pdf.table_icon('fa-check-square-o')
    content1   = icon_empty

    protocol.reload.answers.each do |a|
      question = Question.find(a.question_id)
      text     = question.question rescue "N.D"
    
      column_widths = [400,100]
      data = []
      if question.question_type.to_i.eql? 1  ## multiple option
        column_widths = [30,470]
        pdf.text text, :size=>size, :style=>:bold
        (a.answer.eql? 4) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Excelente"]
        (a.answer.eql? 3) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Bien"]
        (a.answer.eql? 2) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Regular"]
        (a.answer.eql? 1) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Deficiente"]
      elsif question.question_type.to_i.eql? 2 ## text (recomendaciones y comentarios)
        answer = a.comments.blank? ? "N.A." : a.comments
        data << [{:content=>"\n<b>#{text}:</b>",:colspan=>2}]
        data << [{:content=>"#{answer}",:colspan=>2}]
      elsif question.question_type.to_i.eql? 3 ## grade
        answer = a.answer rescue "n.d."
        data << [text,"<b>#{answer}</b>"]
      end
 
      tabla = pdf.make_table(data,:width=>500,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center,:column_widths=>column_widths)
      tabla.draw
    end  ## end protocol.answeers

    pdf.move_down 10
    data = []
    data << [{:content=>"<b>Resultado:</b>",:colspan=>2}]
    
    icon_empty = pdf.table_icon('fa-square-o')
    icon_ok    = pdf.table_icon('fa-check-square-o')
    content1   = icon_empty

    if advance.advance_type.eql? 2 #protocol
      (protocol.grade_status.eql? 1) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"Aprobado"]
      (protocol.grade_status.eql? 2) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"No aprobado"]
    elsif advance.advance_type.eql? 3 #seminar
      (protocol.grade_status.eql? 1) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,{:content=>"Aprobado",:align=>:left}]
      (protocol.grade_status.eql? 2) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"No aprobado"]
      (protocol.grade_status.eql? 3) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"Con Recomendaciones"]
    end
      
    tabla = pdf.make_table(data,:width=>320,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:left,:column_widths=>[30,290])
    tabla.draw

    unless advance.advance_type.eql? 2
      pdf.text "\nCon promedio de <b>#{protocol.grade}</b>", :inline_format=>true
    end

    pdf.font_size 8
    info = "Este documento fue emitido a traves del sistema de posgrado"
    pdf.bounding_box [pdf.bounds.left, pdf.bounds.bottom + 15], :width  => pdf.bounds.width do
      pdf.text info, :size => pdf.font_size, :align=>:left
    end

=begin
    pdf.repeat :all do
      # footer
      pdf.bounding_box [pdf.bounds.left, pdf.bounds.bottom + 15], :width  => pdf.bounds.width do
        pdf.move_down 5
        pdf.text info, :size => pdf.font_size, :align=>:left
      end
    end
=end
    
    pdf.number_pages "Página <page> de <total>", :at=>[pdf.bounds.left , pdf.bounds.bottom], :align=>:right, :size=>pdf.font_size,:inline_format=>true

    pdf.render_file "#{pdf_route}"
  end

  def send_email(advance,opc,address,params)
    ##address = "enrique.turcott@cimav.edu.mx"  ## al atravezado
   
    if opc.eql? 1
      content = "{:email=>\"#{address}\",:view=>10}"
      @email = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>address,:subject=>"Un evaluador ha calificado su protocolo",:content=>content,:status=>0})
    elsif opc.eql? 2
      content = "{:email=>\"#{address}\",:view=>17}"
      @email = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>address,:subject=>"Un evaluador ha calificado su seminario",:content=>content,:status=>0})
    elsif opc.eql? 3
      content = "{:email=>\"#{address}\",:view=>18,:student_id=>#{params[:student_id]}}"
      @email = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>address,:subject=>"Seminario no aprobado",:content=>content,:status=>0})
    elsif opc.eql? 4
      content = "{:email=>\"#{address}\",:view=>19,:student_id=>#{params[:student_id]}}"
      @email = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>address,:subject=>"Seminario con recomendaciones",:content=>content,:status=>0})
    elsif opc.eql? 5
      content = "{:email=>\"#{address}\",:view=>20,:advance_id=>#{advance.id}}"
      @email = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>address,:subject=>"Seminario con recomendaciones",:content=>content,:status=>0})
    end

    @email.save
  end

  def get_consecutive(object, time, type)
    maximum = Certificate.where(:year => time.year,:type_id=>type).maximum("consecutive")

    if maximum.nil?
      maximum = 1
    else
      maximum = maximum + 1
    end

    certificate                 = Certificate.new()
    certificate.consecutive     = maximum
    certificate.year            = time.year
    certificate.attachable_id   = object.id
    certificate.attachable_type = object.class.to_s
    certificate.type_id         = type
    certificate.save

    return "%03d" % maximum
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
