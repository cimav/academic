class Email < ActiveRecord::Base
  attr_accessible :id,:from,:to,:subject,:content,:status
end
