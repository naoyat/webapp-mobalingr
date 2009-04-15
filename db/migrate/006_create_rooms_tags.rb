class CreateRoomsTags < ActiveRecord::Migration
  def self.up
    create_table(:rooms_tags, {:id => false}) do |t|
      t.column :room_cid, :integer
      t.column :tag_cid,  :integer
    end
  end

  def self.down
    drop_table :rooms_tags
  end
end
