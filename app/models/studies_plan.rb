class StudiesPlan < ActiveRecord::Base
  attr_accessible :id, :program_id, :code, :name, :notes, :status, :created_at, :updated_at

  belongs_to :program

  validates :code, :presence => true
  validates :name, :presence => true
  

  ACTIVE   = 1
  INACTIVE = 2
  DELETED  = 99

  STATUS = {ACTIVE   => 'Activo',
            INACTIVE => 'Inactivo',
            DELETED  => 'Borrado'
  }
end
