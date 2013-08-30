# coding: utf-8
class TermCourseStudent < ActiveRecord::Base
  attr_accessible :id,:term_course_id,:term_student_id,:grade,:status,:created_at,:updated_at

  has_many :grade_log

  belongs_to :term_course
  belongs_to :term_student

  ACTIVE   = 1
  INACTIVE = 2

  STATUS = {ACTIVE   => 'Activo',
            INACTIVE => 'Baja'}

  def status_type
    STATUS[status]
  end
end
