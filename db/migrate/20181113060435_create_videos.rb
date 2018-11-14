class CreateVideos < ActiveRecord::Migration[5.2]
  def change
    create_table :videos do |t|
      t.text :name
      t.date :upload_date
      t.text :duration
      t.text :link
      t.boolean :watched
      t.belongs_to :channel, index: true
    end
  end
end
