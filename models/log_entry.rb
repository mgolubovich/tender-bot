# Class for handling logs in mongodb.
class LogEntry
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in session:'logger'
  field :severity, type: Symbol, default: :info
  field :event, type: String
  field :data, type: Hash, default: {}
  field :source_id, type: BSON::ObjectId
end