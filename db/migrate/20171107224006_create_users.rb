class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.integer :balance_in_cents, default: 0
    end
  end
end
