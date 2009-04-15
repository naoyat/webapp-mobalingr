class CreateApiUsages < ActiveRecord::Migration
  def self.up
    create_table :api_usages do |t|
      t.column :api_id,  :string, :limit => 32, :null => false
      t.column :room_id, :string, :limit => 32
      t.column :ticket,  :string, :limit => 20
      t.column :used_at, :timestamp
    end
  end

  def self.down
    drop_table :api_usages
  end
end
