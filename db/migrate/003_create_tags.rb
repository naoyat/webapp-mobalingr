class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.column :name,         :string, :limit => 80 ## single lower-case word
      t.column :display_name, :string, :limit => 80
      t.column :url,          :string, :limit => 100
#     t.column :rank,         :integer # [1..8]
    end
  end

  def self.down
    drop_table :tags
  end
end
