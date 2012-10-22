class TermCourseSchedule < ActiveRecord::Base
  attr_accessible :id,:term_course_id,:day,:start_hour,:end_hour,:classroom_id,:staff_id,:start_date,:end_date,:class_type,:status,:created_at,:updated_at
  belongs_to :term_course
  belongs_to :staff
  belongs_to :classroom

  ACTIVE   = 1
  INACTIVE = 2

  MONDAY    = 1
  TUESDAY   = 2
  WEDNESDAY = 3
  THURSDAY  = 4
  FRIDAY    = 5
  SATURDAY  = 6
  SUNDAY    = 7

  DAY = {MONDAY    => 'Lunes',
         TUESDAY   => 'Martes',
         WEDNESDAY => 'Miercoles',
         THURSDAY  => 'Jueves',
         FRIDAY    => 'Viernes',
         SATURDAY  => 'Sabado',
         SUNDAY    => 'Domingo'}

  PRESENTIAL = 1
  VIRTUAL    = 2

  CLASSTYPE = {PRESENTIAL => 'Presencial',
               VIRTUAL    => 'Virtual'}

  HOURS = [['06:00', '06:00'],
           ['07:00', '07:00'],
           ['08:00', '08:00'],
           ['09:00', '09:00'],
           ['10:00', '10:00'],
           ['11:00', '11:00'],
           ['12:00', '12:00'],
           ['13:00', '13:00'],
           ['14:00', '14:00'],
           ['15:00', '15:00'],
           ['16:00', '16:00'],
           ['17:00', '17:00'],
           ['18:00', '18:00'],
           ['19:00', '19:00'],
           ['20:00', '20:00'],
           ['21:00', '21:00'],
           ['22:00', '22:00']]

  def day_name
    DAY[day]
  end

  def class_type_name
    CLASSTYPE[class_type]
  end
end
