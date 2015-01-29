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
    @stc = TermCourse.joins(:term_course_student=>:term_student).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=? AND term_course_students.status=?",70,1)
    @scourses = @stc.map{|i| i.course_id}

    ## Nos traemos el plan de estudios
    @plan_estudios        = Course.where(:program_id=>@student.program.id,:studies_plan_id=>@student.studies_plan_id).where("term!=99").order(:term)
    @optativas_requeridas = Course.where(:program_id=>@student.program.id,:studies_plan_id=>@student.studies_plan_id).where("term!=99 AND courses.name like '%Optativa%'").size
    @optativas_cursadas   = @stc.joins(:course).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=? AND courses.term=?",70,99).size
    @alternativas_cursadas   = @stc.joins(:course).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=? AND courses.term!=? AND courses.program_id!=?",70,99,@student.program.id).size
    @optativas_total = @optativas_cursadas + @alternativas_cursadas
    @materias_faltantes = []
    @plan_estudios.each do |c|
       logger.debug "PLAN: #{c.name}" 
       if !@scourses.include? c.id
         if c.name.include? "Optativa"
           if @optativas_total>0
             @optativas_total = @optativas_total - 1
           else
             @materias_faltantes << c
           end
         else
           @materias_faltantes << c
         end
       end
    end

    @materias_faltantes.each do |mf|
      logger.debug "FALTAN: #{mf.name}"
      @maxterm = mf.term
    end

    if @materias_faltantes.size>0
      logger.debug "PRIMER REGISTRO:  #{@materias_faltantes[0].name}"
      @maxterm = @materias_faltantes[0].term - 1
    else
      @maxterm = @plan_estudios.maximum(:term) 
    end

    ## Almacenamos en un arreglo los ciclos
    @smaxterm = [@maxterm,@maxterm+1,99]
    
    ## Nos traemos los cursos que no han sido aprobados, es decir, que no estan en scourses y >>
    ## los que estan en el semestre al que pertence el alumno mas uno.
    # tcs = TermCourse.joins(:term=>:program).joins(:course).where(:courses=>{:studies_plan_id=>@student.studies_plan_id},:programs=>{:id=>@student.program.id},:terms=>{:status=>1}).where("terms.id=? AND courses.id not in (?) AND courses.term in (?)",@e_term.id,scourses,smaxterm).order("courses.program_id") 
    @tcs = TermCourse.joins(:term=>:program).joins(:course).where(:courses=>{:studies_plan_id=>@student.studies_plan_id},:programs=>{:id=>@student.program.id},:terms=>{:status=>1}).where("terms.id=? AND courses.id not in (?) AND courses.term<=?",@e_term.id,@scourses,@maxterm+1).order("courses.program_id")    # agregamos los id de los cursos en el mapa de scourses
    @scourses += @tcs.map {|i| i.course_id}
 
    ## Obtenemos todos los cursos para el resto de los programas
    if @student.program.level.to_i.eql? 2
      @levels = [1,2]
    else
      @levels = 1
    end

    @tcs2 = TermCourse.joins(:term=>:program).joins(:course).where(:programs=>{:level=>@levels},:terms=>{:status=>1}).where("courses.id not in (?) AND courses.program_id !=?",@scourses,@student.program.id).order("courses.program_id") 
    
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

    ## asisgnando permisos para inscribir sin materias
    @without_courses = false
    if @student.program.level.to_i.eql? 2 ## los de doctorado
      @without_courses = true
    elsif @student.program.level.to_i.eql? 1 ## los de maestria con una materia de tesis calificada
      t = TermCourse.joins(:term_course_student=>:term_student).joins(:course).where(:term_students=>{:student_id=>@student.id}).where("term_course_students.grade>=? AND courses.notes='[AI]'",70)
      if t.size>0
        @without_courses = true
      end
    end


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
