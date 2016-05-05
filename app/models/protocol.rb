# coding: utf-8
class Protocol < ActiveRecord::Base
  attr_accessible :id,:advance_id,:staff_id,:group,:grade,:created_at,:updated_at

  belongs_to :staffs
  belongs_to :students

  has_many :answers

  CREATED   = 1
  SENT      = 2
  CANCELLED = 3
  
  STATUS = {
    CREATED   => 'Creado',  
    SENT      => 'Enviado',
    CANCELLED => 'Cancelado'
  }
end

