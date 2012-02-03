class Band
  include Mongoid::Document
  field :name, :type => String
  field :members, :type => Array
  field :likes, :type => Integer

  embeds_many :records, :cascade_callbacks => true
  embeds_one :label, :cascade_callbacks => true
end
