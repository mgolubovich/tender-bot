class MongoLogger

  @collection = 'default'
  @source_id = nil


  def initialize(collection)
    @collection = collection
  end

  def set_source(source_id)
    @source_id = source_id
  end

  def info(text, data={})
    add(:info, text, data)
  end

  def error(text, data={})
    add(:error, text, data)
  end

  def add(severity, text, data)
    converted_data = {}
    data.map do |key, val|
      if val.respond_to?(:as_document)
        converted_data[key]=val.as_document
      else
        converted_data[key]=val
      end
    end
    log_entry = LogEntry.new(severity: severity, event: text, source_id: @source_id, data: converted_data)
    log_entry.with(collection: @collection).save!
    converted_data.delete(:screen)
    ap(source_id:@source_id, severity: severity, event: text, data: converted_data)
  end
end