class FeedPopUp
  def self.update_from_feed(feed_url, collection_id)
    able_to_parse = true
    feed = Feedzirra::Feed.fetch_and_parse(feed_url)
    feed = Feedzirra::Feed.fetch_and_parse(feed_url, :on_failure => lambda {|url, response_code, header, body| able_to_parse = false if response_code == 200 })
    if able_to_parse && feed && feed != 0
      add_entries(feed.entries, collection_id)
    else
      puts "Error: Check feed url " + feed_url
    end
  end

  private
  def self.is_audio_file?(url)
    #puts "is_audio_file? url:#{url}"
    uri = URI.parse(url)
    ext = (File.extname(uri.path)[1..-1] || "").downcase
    ['aac', 'aif', 'aiff', 'alac', 'flac', 'm4a', 'm4p', 'mp2', 'mp3', 'mp4', 'ogg', 'raw', 'spx', 'wav', 'wma'].include?(ext)
  rescue  URI::BadURIError
    false
  rescue  URI::InvalidURIError
    false
  end

  def self.add_entries(entries, coll_id)
    collection = Collection.find_by_id(coll_id)
    if collection
      newItems = 0
      entries.each do |entry|
        unless Item.where(identifier: entry.entry_id, collection_id: coll_id).exists?
          item = Item.new
          item.collection = collection
          item.description = entry.summary
          item.title = entry.title
          item.identifier = entry.id
          item.digital_location = entry.url
          item.date_broadcast = entry.published
          entry.media_contents.each do |mediaContent|
            url = mediaContent.url
            next unless self.is_audio_file?(url)
            instance = item.instances.build
            instance.digital = true
            audio = AudioFile.new
            instance.audio_files << audio
            item.audio_files << audio
            audio.identifier = url
            audio.remote_file_url= url
          end
          item.save!
          newItems += 1
        end
      end
      if newItems == 0
        puts "There is nothing new for "+coll_id
      else
        puts  newItems.to_s+" new items for " + coll_id.to_s
      end
    else
      puts "Collection not found!, id: "+coll_id
    end
  end
end
