class Transcript < ActiveRecord::Base
  attr_accessible :language, :audio_file_id, :identifier, :start_time, :end_time

  belongs_to :audio_file
  has_many :timed_texts, order: 'start_time ASC'

  def set_confidence
    sum = 0.0
    count = 0.0
    self.timed_texts.each{|tt| sum = sum + tt.confidence.to_f; count = count + 1.0}
    if count > 0.0
      average = sum / count
      self.update_attribute(:confidence, average)
    end
    average
  end

end
