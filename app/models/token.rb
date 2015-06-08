class Token < ActiveRecord::Base
  attr_accessible :id, :attachable_id, :attachable_type, :token, :expires, :status

  belongs_to :attachable, :polymorphic => true

  ACTIVE     = 1
  USED       = 2
  LOCK       = 3

  STATUS = {ACTIVE => 'Activo',
            USED   => 'Usado',
            LOCK   => 'Bloqueado',
           }
end
