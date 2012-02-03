# encoding: utf-8
require "uri"
require "mongoid/config/environment"
require "mongoid/config/options"

module Mongoid #:nodoc

  # This module defines all the configuration options for Mongoid, including the
  # database connections.
  module Config
    extend self
    extend Options
    include ActiveModel::Observing

    option :allow_dynamic_fields, :default => true
    option :autocreate_indexes, :default => false
    option :identity_map_enabled, :default => false
    option :include_root_in_json, :default => false
    option :include_type_for_serialization, :default => false
    option :persist_in_safe_mode, :default => false
    option :preload_models, :default => false
    option :raise_not_found_error, :default => true
    option :scope_overwrite_exception, :default => false
    option :skip_version_check, :default => false
    option :time_zone, :default => nil
    option :use_activesupport_time_zone, :default => true
    option :use_utc, :default => false

    # Return field names that could cause destructive things to happen if
    # defined in a Mongoid::Document.
    #
    # @example Get the destructive fields.
    #   config.destructive_fields
    #
    # @return [ Array<String> ] An array of bad field names.
    def destructive_fields
      Components.prohibited_methods
    end

    # Load the settings from a compliant mongoid.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Mongoid.
    #   Mongoid.load!("/path/to/mongoid.yml")
    #
    # @param [ String ] path The path to the file.
    #
    # @since 2.0.1
    def load!(path)
      Environment.load_yaml(path).tap do |settings|
        load_configuration(settings) if settings.present?
      end
    end

    # Returns the default logger, which is either a Rails logger of stdout logger
    #
    # @example Get the default logger
    #   config.default_logger
    #
    # @return [ Logger ] The default Logger instance.
    def default_logger
      defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : ::Logger.new($stdout)
    end

    def load_configuration(settings)
      configuration = settings.with_indifferent_access
      self.databases = configuration[:databases]
      self.options = configuration[:options]
      self.sessions = configuration[:sessions]
    end

    def databases
      @databases ||= {}
    end

    def databases=(databases)
      # @todo: Durran: Validate database options.
      @databases = databases.with_indifferent_access
    end

    def options=(options)
      # @todo: Durran: Validate options.
      options.each_pair do |option, value|
        send("#{option}=", value)
      end
    end

    def sessions
      @sessions ||= {}
    end

    def sessions=(sessions)
      # @todo: Durran: Validate session options.
      @sessions = sessions.with_indifferent_access
    end

    # Returns the logger, or defaults to Rails logger or stdout logger.
    #
    # @example Get the logger.
    #   config.logger
    #
    # @return [ Logger ] The configured logger or a default Logger instance.
    def logger
      @logger = default_logger unless defined?(@logger)
      @logger
    end

    # Sets the logger for Mongoid to use.
    #
    # @example Set the logger.
    #   config.logger = Logger.new($stdout, :warn)
    #
    # @return [ Logger ] The newly set logger.
    def logger=(logger)
      case logger
      when false, nil then @logger = nil
      when true then @logger = default_logger
      else
        @logger = logger if logger.respond_to?(:info)
      end
    end

    # Purge all data in all collections, including indexes.
    #
    # @example Purge all data.
    #   Mongoid::Config.purge!
    #
    # @since 2.0.2
    def purge!
      session = Threaded.sessions[:default] || Sessions::Factory.default
      session.use Mongoid.databases[:default][:name]
      collections = session["system.namespaces"].find(name: { "$not" => /system|\$/ }).to_a
      collections.each do |collection|
        _, name = collection["name"].split(".", 2)
        session[name].drop
      end
    end
  end
end
