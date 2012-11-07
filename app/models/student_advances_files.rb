class StudentAdvancesFiles < ActiveRecord::Base
  attr_accessible :id, :term_student_id,:student_advance_type,:description,:file
  mount_uploader :file, StudentAdvancesFileUploader

  SEMESTER = 1
  INTERSEMESTER = 2
  STUDENT_ADVANCE_TYPE  = {
    SEMESTER       => "Semestral",
    INTERSEMESTER  => "Intersemestral",
  }
end
