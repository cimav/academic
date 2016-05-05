# coding: utf-8
class Answer < ActiveRecord::Base
  attr_accessible :id,:question_id,:protocol_id,:answer,:comments,:created_at,:updated_at
  belongs_to :questions
  belongs_to :protocols
end

