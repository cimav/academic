# coding: utf-8
class Protocol < ActiveRecord::Base
  attr_accessible :id,:advance_id,:staff_id,:group,:grade,:status,:created_at,:updated_at

  belongs_to :staffs
  belongs_to :students
  belongs_to :advances

  has_many :answers

  before_validation(on: :create) do
    if Protocol.where(:advance_id=>self.advance_id,:staff_id=>self.staff_id,:group=>self.group,:grade=>self.grade,:status=>self.status).first.present?
      self.errors.add(:id, "register is repeated")
    end
  end

  CANCELLED   = 1
  SENT        = 2
  CREATED     = 3
  RECOMMENDED = 4
  
  STATUS = {
    CREATED     => 'Creado',  
    SENT        => 'Enviado',
    CANCELLED   => 'Cancelado',
    RECOMMENDED => 'En recomendaciones'
  }

end

