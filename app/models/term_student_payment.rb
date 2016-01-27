class TermStudentPayment < ActiveRecord::Base
  attr_accessible :id,:term_student_id,:amount,:status,:created_at,:updated_at
  belongs_to :term_student

  NONE     = 1
  PARTIAL  = 2
  TOTAL    = 3

  STATUS = {NONE    => 'Ninguno',
            PARTIAL => 'Parcial',
            TOTAL   => 'Total'}

  def status_type
   STATUS[status]
  end
end

