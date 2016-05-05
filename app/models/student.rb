class Student < ActiveRecord::Base
  attr_accessible :id,:program_id,:card,:previous_card,:consecutive,:first_name,:last_name,:gender,:date_of_birth,:city,:state_id,:country_id,:email,:previous_institution,:previous_degree_type,:previous_degree_desc,:previous_degree_date,:contact_id,:start_date,:end_date,:graduation_date,:inactive_date,:supervisor,:co_supervisor,:department_id,:curp,:ife,:cvu,:location,:ssn,:blood_type,:accident_contact,:accident_phone,:passport,:image,:status,:notes,:created_at,:updated_at,:campus_id,:contact_attributes,:scholarship_attributes,:thesis_attributes,:email_cimav,:domain_password,:advance_attributes,:studies_plan_id
 
  default_scope where(:deleted=>0)

  belongs_to :program
  belongs_to :campus

  belongs_to :staff_supervisor, :foreign_key => "supervisor", :class_name => "Staff"
  belongs_to :staff_co_supervisor, :foreign_key => "co_supervisor", :class_name => "Staff"

  belongs_to :state
  belongs_to :country

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  has_one :thesis
  accepts_nested_attributes_for :thesis

  has_many :scholarship
  accepts_nested_attributes_for :scholarship

  has_many :advance
  accepts_nested_attributes_for :advance

  has_many :student_file
  accepts_nested_attributes_for :student_file

  has_many :term_students
  accepts_nested_attributes_for :term_students

  has_many :student_advances_file_message, :as => :attachable
  accepts_nested_attributes_for :student_advances_file_message
  
  has_many :protocol

  ACTIVE    = 1
  GRADUATED = 2
  INACTIVE  = 3
  UNREGISTERED = 4
  FINISH = 5
  PENROLLMENT  = 6

  STATUS = {ACTIVE    => 'Activo',
            FINISH => 'Egresado no graduado',
            GRADUATED => 'Graduado',
            INACTIVE  => 'Baja temporal',
            UNREGISTERED  => 'Baja definitiva',
            PENROLLMENT   => 'Pre-inscrito'
           }

  def status_type
    STATUS[status]
  end

  def full_name
    "#{first_name} #{last_name}" rescue ''
  end

  def full_name_by_last
    "#{last_name} #{first_name}" rescue ''
  end

  def full_name_with_card
    "#{card}: #{first_name} #{last_name}" rescue ''
  end
end
