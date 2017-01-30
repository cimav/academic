# coding: utf-8
class User < ActiveRecord::Base
  attr_accessible :id,:email,:access,:status,:created_at,:updated_at,:program_id,:campus_id,:program_type,:areas,:permission_user_attributes

  belongs_to :campus
  #has_many :permission_user
  #accepts_nested_attributes_for :permission_user

  #before_save :delete_permissions

  ADMINISTRATOR = 1
  OPERATOR      = 2
  STAFF         = 3
  STUDENT       = 4
  MANAGER       = 5

  STATUS_ACTIVE   = 1
  STATUS_INACTIVE = 2

  ACCESS_TYPE = {STUDENT       => 'Estudiante',
                 STAFF         => 'Docente',
                 OPERATOR      => 'Operador',
                 ADMINISTRATOR => 'Administrador',
                 MANAGER       => 'Jefe de Posgrado'}


  STATUS = {STATUS_INACTIVE => 'Inactivo',
            STATUS_ACTIVE   => 'Activo'}

  validates :email, :presence => true, :uniqueness => true
  validates :access, :presence => true

  def access_type
    ACCESS_TYPE[access]
  end



  #def delete_permissions
  #  PermissionUser.delete_all(:user_id => self.id)
  #end
end

