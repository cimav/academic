# coding: utf-8
class Advance < ActiveRecord::Base
  attr_accessible :id,:student_id,:title,:advance_date,:tutor1,:tutor2,:tutor3,:tutor4,:tutor5,:status,:notes,:created_at,:updated_at
 
  default_scope joins(:student).where('students.deleted=?',0).order('advance_date DESC').readonly(false)

  belongs_to :student
  
  has_one :protocol
  
  ADVANCE  = 1
  PROTOCOL = 2
            
  TYPE = {  
    ADVANCE   => 'Avance programático',
    PROTOCOL  => 'Evaluación de protocolo',
  }
end
