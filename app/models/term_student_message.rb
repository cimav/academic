class TermStudentMessage < ActiveRecord::Base
  attr_accessible :id,:term_student_id,:message,:created_at,:updated_at
  belongs_to :term_student
end
