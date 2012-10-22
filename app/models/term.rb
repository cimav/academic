class Term < ActiveRecord::Base
  attr_accessible :id,:program_id,:code,:name,:start_date,:end_date,:status,:created_at,:updated_at,:term_students_attributes,:term_courses_attributes
  belongs_to :program

  has_many :term_courses
  accepts_nested_attributes_for :term_courses

  has_many :term_students
  accepts_nested_attributes_for :term_students

  OPEN      = 1
  PROGRESS  = 2
  GRADING   = 3
  ENDED     = 4
  CANCELED  = 5

  STATUS = {OPEN     => 'Abierto',
            PROGRESS => 'En progreso',
            GRADING  => 'Calificando',
            ENDED    => 'Finalizado',
            CANCELED => 'Cancelado'}

  def status_type
    STATUS[status]
  end

  def assign_courses(courses)
    index = 0
    courses_in_tc = []
    params = Hash.new
    params[:term_courses_attributes] = Hash.new

    self.term_courses.each do |tc|
      courses_in_tc << tc.course_id
      if !courses.include?(tc.course_id)
        params[:term_courses_attributes][index] = {:id => tc.id, :status => TermCourse::UNASSIGNED}
        index += 1
      else
        params[:term_courses_attributes][index] = {:id => tc.id, :status => TermCourse::ASSIGNED}
        index += 1
      end
    end

    courses.each do |c|
      if !courses_in_tc.include?(c)
        params[:term_courses_attributes][index] = {:course_id => c, :status => TermCourse::ASSIGNED}
        index += 1
      end
    end

    self.update_attributes(params)

  end

end
