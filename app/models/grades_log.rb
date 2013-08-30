class GradesLog < ActiveRecord::Base
  attr_accessible :id, :staff_id, :term_course_student_id
  belongs_to :staff
  belongs_to :term_course_student
end
