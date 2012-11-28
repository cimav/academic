class StudentAdvancesFileMessage < ActiveRecord::Base
  attr_accessible :id,:student_advances_file_id,:attachable_id,:attachable_type,:message

  belongs_to :attachable, :polymorphic => true
  belongs_to :student_advances_file
  belongs_to :student
  belongs_to :staff

  validates :student_advances_file_id, :presence=>true
  validates :attachable_id, :presence=>true
  validates :attachable_type, :presence=>true
  validates :message, :presence=>true
end
