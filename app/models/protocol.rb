# coding: utf-8
class Protocol < ActiveRecord::Base
  attr_accessible :id,:advance_id,:staff_id,:group,:grade,:created_at,:updated_at

  belongs_to :staffs
  belongs_to :students
  belongs_to :advances

  has_many :answers

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

