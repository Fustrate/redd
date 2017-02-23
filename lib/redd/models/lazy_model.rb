# frozen_string_literal: true

require_relative 'basic_model'

module Redd
  module Models
    # The base class for lazily-initializable models.
    class LazyModel < BasicModel
      # Create a lazily initialized class.
      # @param client [APIClient] the client that the model uses to make requests
      # @param base_attributes [Hash] the already-known attributes that do not need to be looked up
      # @yield [client] the model's client
      # @yieldparam client [APIClient]
      # @yieldreturn [Hash] the response of "initializing" the lazy model
      def initialize(client, base_attributes = {}, &block)
        super(client, base_attributes)
        @lazy_loader = block
        @definitely_fully_loaded = false
      end

      # @return [Boolean] whether the model can be to be lazily initialized
      def lazy?
        !@lazy_loader.nil?
      end

      # Force the object to make a request to reddit.
      # @return [self]
      def force_load
        return unless lazy?
        @attributes.merge!(@lazy_loader.call(@client))
        @definitely_fully_loaded = true
        self
      end
      alias reload force_load

      # Convert the object to a hash, making a request to fetch additional attributes if needed.
      # @return [Hash]
      def to_h
        ensure_fully_loaded
        super
      end

      private

      # Make sure the model is loaded at least once.
      def ensure_fully_loaded
        force_load if lazy? && !@definitely_fully_loaded
      end

      # Gets the attribute and loads it if it may be available from the response.
      def get_attribute(name)
        ensure_fully_loaded unless @attributes.key?(name)
        super
      end

      # Checks whether an attribute exists, loading it first if necessary.
      def attribute?(name)
        ensure_fully_loaded unless @attributes.key?(name)
        super
      end
    end
  end
end