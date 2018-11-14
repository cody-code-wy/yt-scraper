class Video < ActiveRecord::Base
  belongs_to :channel, required: true
end
