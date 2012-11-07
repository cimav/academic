class Program < ActiveRecord::Base
  attr_accessible :id,:name,:level,:prefix,:description,:created_at,:updated_at,:terms_duration,:terms_qty,:program_type,:terms_attributes
  has_many :documentation_file
  accepts_nested_attributes_for :documentation_file

  MASTER        = 1
  DOCTORATE     = 2
  PROPADEUTIC   = 3
  POSTDOCTORATE = 4
  DIPLOMA       = 5

  SEMESTER      = 1
  QUADMESTER    = 2
  TRIMESTER     = 3

  ALL                  = 0
  P_ACADEMICOS         = 2
  P_FORMACION_CONTINUA = 3
  P_PROPEDEUTICOS      = 4


  LEVEL = {POSTDOCTORATE => 'Postdoctorado',
           DOCTORATE     => 'Doctorado',
           MASTER        => 'Maestra',
           PROPADEUTIC   => 'Propedutico',
           DIPLOMA       => 'Diplomado'}

  TERM = {TRIMESTER  => 'Trimestre',
          QUADMESTER => 'Cuatrimestre',
          SEMESTER   => 'Semestre'}

  PROGRAM_TYPE = {ALL                   => 'Todos los tipos de programa',
                  P_ACADEMICOS          => 'Programas Acadmicos',
                  P_FORMACION_CONTINUA  => 'Programas de Formacin Continua',
                  P_PROPEDEUTICOS       => 'Programas Propeduticos'}

  has_many :students

  has_many :permission_user

  has_many :courses
  accepts_nested_attributes_for :courses

  has_many :terms
  accepts_nested_attributes_for :terms

  def level_type
    LEVEL[level]
  end

  def term_type
    TERM[terms_duration]
  end
end
