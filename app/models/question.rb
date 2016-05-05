# coding: utf-8
class Question < ActiveRecord::Base
  attr_accessible :id,:group,:question_type,:order,:question,:created_at,:updated_at
  has_many :answers
end

