class StudentAdvancesFiles < ActiveRecord::Base
  attr_accessible :id, :term_student_id,:student_advance_type,:description,:file

  default_scope joins(:term_student=>[:student]).where('students.deleted=?',0).readonly(false)

  mount_uploader :file, StudentAdvancesFileUploader

  belongs_to :term_student
  has_many :student_advances_file_message
  accepts_nested_attributes_for :student_advances_file_message

  SEMESTER = 1
  INTERSEMESTER = 2
  PROTOCOL = 3
  STUDENT_ADVANCE_TYPE  = {
    SEMESTER       => "Semestral",
    INTERSEMESTER  => "Intersemestral",
    PROTOCOL => "Protocolo",
  }
end
