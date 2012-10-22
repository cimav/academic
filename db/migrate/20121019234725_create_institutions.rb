class CreateInstitutions < ActiveRecord::Migration
  def change
    create_table :institutions do |t|

      t.timestamps
    end
  end
end
