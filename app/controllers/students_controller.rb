# coding: utf-8
class StudentsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json
  $CICLO = "2016-2"
  $NCICLO = "2017-1"

  def enrollment_courses
    @student   = Student.find(params[:id])
    ## get last term tha
    campus_short_name = @student.campus.short_name
    #last_term  = Term.joins(:term_students=>:student).where(:students=>{:id=>@student.id}).order("terms.end_date desc").limit(1)[0] rescue ""
    last_term = Term.where("name like '%#{$NCICLO}%' and name like '%#{campus_short_name}%' and program_id=? and status=1",@student.program_id).last
    #last_term  = Term.where("name like '%2016-1%' and program_id=?",@student.program_id).last
    @ts  = TermStudent.where(:student_id=>@student.id,:term_id=>last_term.id).last
    logger.info "######################### #{@ts}"
    @tcs = TermCourseStudent.where(:term_student_id=>@ts.id,:status=>6)
    @tsp = TermStudentPayment.where(:term_student_id=>@ts.id,:status=>6)

    render :layout => false
  end

  def assign_courses
    json = {}
    @message  = ""
    @errors   = []
    @action = params[:haction]
    @ts = TermStudent.find(params[:ts_id])
    @s  = @ts.student

    if @action.to_i.eql? 1
      @s.status = 1
      @ts.status = 1
      if @s.save
        if @ts.save
          @ts.term_course_student.each do |tcs|
            tcs.status=1
            if !tcs.save
              @message = "Error al cambiar estatus de curso"
              @errors << 3
            end # if !tcs
          end#each tcs
        else
          @message = "Error al cambiar estatus del ciclo"
          @errors << 2
        end # if save ts
      else
        @message = "Error al cambiar estatus del alumno"
        @errors << 1
      end  ## if save student
    elsif @action.to_i.eql? 2
      @ts.status = 7
      tsm = TermStudentMessage.new
      tsm.term_student_id = @ts.id
      tsm.message = params[:refuse_area]
      tsm.save
      @ts.status = 7
      @ts.save
      json[:response]=2
    else
      @message = "Error en la accion"
      @errors << 221
    end ## if action

    if @errors
      ## mandamos email al alumno
      if @action.to_i.eql? 1
        @view = 6
        @subject = "Inscripcion realizada de forma exitosa"
      elsif @action.to_i.eql? 2
        @view = 7
        @subject = "Inscripcion rechazada por el director de tesis"
      end
      to = @s.email_cimav
      content = "{:view=>#{@view}}"
      subject = "#{@subject}"
      mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})
      mail.save
    end



    respond_with do |format|
      format.html do
        if request.xhr?
          json[:message] = @message
          json[:errors]  = @errors
          json[:s_id]    = params[:s_id]
          render :json => json
        else
          render :layout => false
        end
      end
    end
  end
end
