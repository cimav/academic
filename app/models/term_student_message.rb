class TermStudentMessage < ActiveRecord::Base
  attr_accessible :id,:term_student_id,:message,:created_at,:updated_at
  validates_uniqueness_of :term_student_id, scope: [:message]
  belongs_to :term_student
end
