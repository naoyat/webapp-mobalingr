class Tag < ActiveRecord::Base
  has_and_belongs_to_many :rooms,
  :foreign_key => 'tag_cid',
  :association_foreign_key => 'room_cid'

  def self.with_hash(hash)
    begin
      tag = self.find(:first, :conditions => ['name = ?', hash['name']])
    rescue
      tag = nil
    end

    if tag
      tag.update_attributes(:display_name => hash['display_name'],
                            :url          => hash['url'])
    else
      tag = self.create(:name         => hash['name'],
                        :display_name => hash['display_name'],
                        :url          => hash['url']
                        #                :rank => hash['rank']
                        )
    end
    tag
  end
end
