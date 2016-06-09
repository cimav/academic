# coding: utf-8
class Advance < ActiveRecord::Base
  attr_accessible :id,:student_id,:title,:advance_date,:tutor1,:tutor2,:tutor3,:tutor4,:tutor5,:status,:notes,:created_at,:updated_at,:advance_type
 
  default_scope joins(:student).where('students.deleted=?',0).order('advance_date DESC').readonly(false)

  belongs_to :student
  
  has_many :protocols
  
  ADVANCE  = 1
  PROTOCOL = 2
  SEMINAR  = 3
            
  TYPE = {  
    ADVANCE   => 'Avance programático',
    PROTOCOL  => 'Evaluación de protocolo',
    SEMINAR   => 'Evaluación de seminario',
  }
end
