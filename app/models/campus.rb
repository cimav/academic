class Campus < ActiveRecord::Base
  attr_accessible :id,:short_name,:name,:contact_id,:image,:created_at,:updated_at

  has_many :students, :order => "first_name, last_name"
  has_many :laboratories
  has_many :user

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  def full_name
    "#{name} (#{short_name})" rescue ''
  end
end
