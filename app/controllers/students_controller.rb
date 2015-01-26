# coding: utf-8
class StudentsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def enrollment_courses
    @student   = Student.find(params[:id])
    ## get last term tha
    last_term  = Term.joins(:term_students=>:student).where(:students=>{:id=>@student.id}).order("terms.end_date desc").limit(1)[0]
    ## get enrollment term
    @e_term    = Term.where("program_id=#{@student.program.id} AND start_date  > '#{last_term.end_date}' AND name like '%#{last_term.name.split(" ")[1]}%'").last
    ## Obtenemos las materias que ya lleva acreditadas el alumno
    @stc = TermCourse.joins(:term_course_student=>:term_student).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=?",70)
    ## Obtenemos la lista de los ciclos a los que pertenecen los cursos aprobados y seleccionamos el ultimo, este es el semestre al que pertenece el alumno
    @maxterm  = @stc.joins(:course).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=? AND courses.term!=?",70,99).maximum("courses.term")
    ## Almacenamos en un arreglo los ciclos
    @smaxterm = [@maxterm,@maxterm+1,99]
    ## Almacenamos en un mapa los cursos acreditados por id
    @scourses = @stc.map{|i| i.course_id}
    
    ## Nos traemos los cursos que no han sido aprobados, es decir, que no estan en scourses y >>
    ## los que estan en el semestre al que pertence el alumno mas uno.
    # tcs = TermCourse.joins(:term=>:program).joins(:course).where(:courses=>{:studies_plan_id=>@student.studies_plan_id},:programs=>{:id=>@student.program.id},:terms=>{:status=>1}).where("terms.id=? AND courses.id not in (?) AND courses.term in (?)",@e_term.id,scourses,smaxterm).order("courses.program_id") 
    @tcs = TermCourse.joins(:term=>:program).joins(:course).where(:courses=>{:studies_plan_id=>@student.studies_plan_id},:programs=>{:id=>@student.program.id},:terms=>{:status=>1}).where("terms.id=? AND courses.id not in (?) AND courses.term<=?",@e_term.id,@scourses,@maxterm+1).order("courses.program_id")    # agregamos los id de los cursos en el mapa de scourses
    @scourses += @tcs.map {|i| i.course_id}
 
    ## Obtenemos todos los cursos para el resto de los programas
    @tcs2 = TermCourse.joins(:term=>:program).joins(:course).where(:programs=>{:level=>[1,2]},:terms=>{:status=>1}).where("courses.id not in (?) AND courses.program_id !=?",@scourses,@student.program.id).order("courses.program_id") 
    
    ## OPTATIVAS
    ## Obtenemos de nuevo los cursos acreditados
    @scourses = TermCourse.joins(:term_course_student=>:term_student).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=?",70).map {|i| i.course_id}
    # Obtenemos las materias del plan de estudios que faltan
    @cs = Course.where("program_id=? AND term<=? AND id not in (?)",@student.program.id,@maxterm+1,@scourses)
    # obtenemos la cantidad de optativas que ya han sido aprobadas
    @optativas = TermCourse.joins(:term_course_student=>:term_student).joins(:course).where("term_students.student_id=? AND courses.program_id=? AND term_course_students.grade>=? AND courses.term=?",@student.id,@student.program.id,70,99)
    @soptativas = @optativas.map{|i| i.course_id} 
    # ahora las optativas que faltan para el programa
    @soptativas << 0
    @optativasf = TermCourse.joins(:course).where("courses.program_id=? AND courses.id not in (?) AND courses.term=? AND term_id=?",@student.program.id,@soptativas,99,@e_term.id)

    respond_to do |format|
      format.html do
        render :layout=> false
      end
    end
  end

  def assign_courses
    json = {}
    @message  = ""
    @errors   = []
    @none  = params[:chk_none]
    #@errors   << 3
    ## primero pre-inscribimos al alumno al ciclo
    @ts = TermStudent.new
    @ts.term_id    = params[:eterm]
    @ts.student_id = params[:s_id] 
    @ts.status     = 6
    if @ts.save 
      if @none.nil?
      ## Ahora inscribimos a los cursos
        params[:tcourses].each do |tc|
          #@errors << tc.to_s
          @tcs = TermCourseStudent.new
          @tcs.term_course_id  = tc
          @tcs.term_student_id = @ts.id
          @tcs.status          = 6
          if @tcs.save
            @message= "Todo OK"
            ## Enviamos mail al alumno (ponemos en la cola de correos el mensaje)
            s = Student.find(params[:s_id])
            to = s.email_cimav
            content = "{:full_name=>\"#{s.full_name}\",:s_id=>\"#{s.id}\",:view=>5}"
            subject = "Ya estan listas sus materias para inscripción"
            mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})
            mail.save
          else
            @message= "No se pudo inscribir a las materias"
            @errors << tc
          end#if
        end#params
      else
        @message="todo ok"
      end#if none
    else
      @message= "No se pudo inscribir al ciclo"
      @errors  << 1 
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
