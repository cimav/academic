# coding: utf-8
class Area < ActiveRecord::Base
  attr_accessible :name, :area_type, :leader, :position, :notes

  has_one :staff

  validates :name, :presence => true
  validates :area_type, :presence=>true, :numericality => {:greater_than => 0}

  NONE         = 0
  DIRECTION    = 1
  COORDINATION = 2
  DEPARTMENT   = 3

  TYPE = {
    NONE         => 'Elegir tipo de area',
    DIRECTION    => 'Dirección',
    COORDINATION => 'Coordinación',
    DEPARTMENT   => 'Departamento'
   }

  def type_type
    TYPE[type]
  end
end

