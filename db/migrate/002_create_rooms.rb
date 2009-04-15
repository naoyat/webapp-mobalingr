class CreateRooms < ActiveRecord::Migration
  def self.up
    create_table :rooms do |t|
      t.column :room_id,             :string, :limit => 32
      t.column :name,                :string #, :limit =>
      t.column :description,         :string #
      t.column :url,                 :string #
      t.column :icon_url,            :string # http://images.lingr.com/object_type/object_id/image_size.gif
      t.column :counter,             :integer
      t.column :max_user_message_id, :integer
      # :tags
      t.column :requires_password,   :boolean
      t.column :chatter_count,       :integer
      t.column :observer_count,      :integer
      t.column :timezone,            :string, :limit => 32
    end
  end

  def self.down
    drop_table :rooms
  end
end
