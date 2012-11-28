class StudentAdvancesFiles < ActiveRecord::Base
  attr_accessible :id, :term_student_id,:student_advance_type,:description,:file
  mount_uploader :file, StudentAdvancesFileUploader

  has_many :student_advances_file_message
  accepts_nested_attributes_for :student_advances_file_message

  SEMESTER = 1
  INTERSEMESTER = 2
  STUDENT_ADVANCE_TYPE  = {
    SEMESTER       => "Semestral",
    INTERSEMESTER  => "Intersemestral",
  }
end
