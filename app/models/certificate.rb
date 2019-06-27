class Certificate < ActiveRecord::Base
  attr_accessible :id, :consecutive, :year, :attachable_id, :attachable_type, :type_id

  belongs_to :attachable, :polymorphic => true
  
  STUDIES           = 1
  ENROLLMENT        = 2
  VISA              = 3
  AVERAGE           = 4
  SEMESTER_AVERAGE  = 5
  SOCIAL_WELFARE    = 6
  CREDITS           = 7
  ACCEPTANCE        = 8
  RELEASE           = 9
  USE               = 10
  EXAMINER          = 11
  APP_ACCEPTANCE    = 12
  STAFF_THESIS_DIR  = 13
  STAFF_SINODAL     = 14
  STAFF_RH          = 15
  STAFF_INDIVIDUAL  = 16
  PROTOCOL          = 17
  SEMINAR           = 18

  TYPE = {STUDIES           => 'Constancia de estudios',
          ENROLLMENT        => 'Constancia de inscripcion',
          VISA              => 'Constancia para VISA',
          AVERAGE           => 'Constancia de Promedio General',
          SEMESTER_AVERAGE  => 'Constancia de Promedio Semestral',
          SOCIAL_WELFARE    => 'Constancia para tramite de seguro',
          CREDITS           => 'Constancia de creditos cubiertos',
          ACCEPTANCE        => 'Carta de aceptacion de servicio social',
          RELEASE           => 'Carta de liberacion del servicio social',
          USE               => 'Carta de uso de informacion',
          EXAMINER          => 'Constancia para sinodales externos',
          APP_ACCEPTANCE    => 'Carta de aceptacion de aspirante',
          STAFF_THESIS_DIR  => 'Constancia de director de tesis',
          STAFF_SINODAL     => 'Constancia como sinodal',
          STAFF_RH          => 'Constancia formación de RH',
          STAFF_INDIVIDUAL  => 'Constancia individual',
          PROTOCOL          => 'Protocolo',
          SEMINAR           => 'Seminario'
          }
end
