class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
# user_info
      t.column :user_id,          :integer
      t.column :email,            :string, :limit => 64
      t.column :default_nickname, :string, :limit => 32
      t.column :icon_url,         :string, :limit => 128
      t.column :counter,          :integer
      t.column :description,      :string

      t.column :valid,            :boolean
      t.column :carrier,          :string, :limit => 1  # d(ocomo) s(oftbank) a(u) w(illcom) ...
      t.column :uid,              :string, :limit => 40
      t.column :password,         :string, :limit => 40
      t.column :last_login,       :datetime
      t.column :easy_login,       :boolean, :default => false

      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
  end

  def self.down
    drop_table :users
  end
end
