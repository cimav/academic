class CreateTermStudents < ActiveRecord::Migration
  def change
    create_table :term_students do |t|

      t.timestamps
    end
  end
end
