class CreateTickets < ActiveRecord::Migration[5.0]
  def change
    create_table :tickets do |t|
      t.integer :event_id, null: false
      t.integer :user_id
    end
  end
end
