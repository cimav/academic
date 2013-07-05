# coding: utf-8
class Classroom < ActiveRecord::Base
  attr_accessible :id,:code,:name,:room_type,:created_at,:updated_at
  has_many :term_course_schedule

  validates :name, :presence => true
  validates :code, :presence => true

  CLASSROOM   = 1
  OFFICE      = 2
  MEETINGROOM = 3
  AUDITORIUM  = 4

  ROOMS = {CLASSROOM    => 'Salón',
           OFFICE       => 'Oficina',
           MEETINGROOM  => 'Sala de Juntas',
           AUDITORIUM   => 'Auditorio'}

  def room_type_text
    ROOMS[room_type]
  end


  def full_name
    "#{code}: #{name}" rescue name
  end
end
