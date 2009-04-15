class CreateRoomsUsers < ActiveRecord::Migration
  def self.up
    create_table(:rooms_users, {:id => false}) do |t|
      t.column :room_cid, :integer
      t.column :user_cid, :integer
      t.column :room_group, :string, :limit => 16
    end
  end

  def self.down
    drop_table :rooms_users
  end
end
