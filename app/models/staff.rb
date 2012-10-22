class Staff < ActiveRecord::Base
  attr_accessible :id,:employee_number,:title,:first_name,:last_name,:gender,:date_of_birth,:location,:email,:institution_id,:contact_id,:cvu,:sni,:status,:image,:notes,:created_at,:updated_at,:lab_practices_attributes,:seminars_attributes,:external_courses_attributes
  belongs_to :institution
  has_many :term_course_schedule

  has_many :seminars
  accepts_nested_attributes_for :seminars

  has_many :external_courses
  accepts_nested_attributes_for :external_courses

  has_many :lab_practices
  accepts_nested_attributes_for :lab_practices

  has_many :internships

  has_many :supervised, :class_name => "Student", :foreign_key => :supervisor
  has_many :co_supervised, :class_name => "Student", :foreign_key => :co_supervisor

  has_many :term_courses
  has_many :staff_file
  accepts_nested_attributes_for :staff_file

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :institution_id, :presence => true

  after_create :add_extra

  mount_uploader :image, StaffImageUploader
  ACTIVE    = 0
  INACTIVE  = 1

  STATUS = {ACTIVE    => 'Activo',
            INACTIVE  => 'Inactivo'}

  def full_name
    "#{first_name} #{last_name}" rescue ''
  end

  def full_name_by_last
    "#{last_name} #{first_name}" rescue ''
  end

  def add_extra
    self.build_contact()
    self.save(:validate => false)
  end
end
