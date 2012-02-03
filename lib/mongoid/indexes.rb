# encoding: utf-8
module Mongoid #:nodoc
  module Indexes #:nodoc
    extend ActiveSupport::Concern

    included do
      cattr_accessor :index_options
      self.index_options = {}
    end

    module ClassMethods #:nodoc

      # Send the actual index creation comments to the MongoDB driver
      #
      # @example Create the indexes for the class.
      #   Person.create_indexes
      def create_indexes
        return unless index_options
        index_options.each_pair do |spec, options|
          collection.indexes.create(spec, options)
        end
      end

      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      #
      # @example Add Mongoid internal indexes.
      #   Person.add_indexes
      def add_indexes
        if hereditary? && !index_options[{ _type: 1 }]
          index _type: 1, unique: false, background: true
        end
        create_indexes if Mongoid.autocreate_indexes
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      #
      # @example Create a basic index.
      #   class Person
      #     include Mongoid::Document
      #     field :name, type: String
      #     index name: 1, background: true
      #   end
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The index options.
      def index(spec)
        # @todo: Durran: Add Hash#delete_first
        definition = spec.to_a
        name = Hash[[definition.delete_one(definition.first)]]
        index_options[name] = { unique: false }.merge(Hash[definition])
        create_indexes if Mongoid.autocreate_indexes
      end
    end
  end
end
