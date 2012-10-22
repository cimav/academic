class TermCourse < ActiveRecord::Base
  attr_accessible :id,:term_id,:course_id,:status,:created_at,:updated_at,:staff_id,:group,:term_course_students_attributes,:term_course_schedules_attributes
  belongs_to :term
  belongs_to :course
  belongs_to :staff

  has_many :term_course_schedules
  accepts_nested_attributes_for :term_course_schedules

  has_many :term_course_students
  accepts_nested_attributes_for :term_course_students

  ASSIGNED   = 1
  UNASSIGNED = 2

  after_create :set_group

  def set_group
    g = TermCourse.where(:term_id => self.term_id).where(:course_id => self.course_id).maximum('group')
    if g.nil?
      g = 'A'
    else
      g = g.next
    end
    self.group = g
    self.save
  end

end
