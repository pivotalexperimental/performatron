ActiveRecord::Schema.define(:version => 1) do
  create_table :somethings, :force => true do |t|
    t.string :name
    t.integer :number

    t.timestamps
  end
end