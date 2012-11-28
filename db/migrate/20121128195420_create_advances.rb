class CreateAdvances < ActiveRecord::Migration
  def change
    create_table :advances do |t|

      t.timestamps
    end
  end
end
