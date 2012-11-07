class CreateStudentAdvancesFiles < ActiveRecord::Migration
  def change
    create_table :student_advances_files do |t|

      t.timestamps
    end
  end
end
