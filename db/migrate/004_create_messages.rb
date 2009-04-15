class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
#      t.column :message_id,    :integer
      t.column :type, :string, :limit => 32
      t.column :occupant_id,   :integer
      t.column :user_id,       :integer
      t.column :nickname,      :string, :limit => 32
      t.column :new_nickname,  :string, :limit => 32
      t.column :source,        :string, :limit => 13 # www.lingr.com
      t.column :client_type,   :string, :limit => 9 # human | automaton
      t.column :icon_url,      :string
      t.column :timestamp,     :timestamp
      t.column :room_id,       :string, :limit => 32
      t.column :score,         :float
      t.column :text,          :string
    end
  end

  def self.down
    drop_table :messages
  end
end
