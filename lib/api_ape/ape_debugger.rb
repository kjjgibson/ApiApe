require 'singleton'
require 'api_ape/ape_debug_log'

module ApiApe
  class ApeDebugger

    module DebugType
      WARNING = 'warning'
      INFO = 'info'
      ALL = 'all'
    end

    include Singleton

    attr_accessor :messages

    def initialize
      @messages = []
    end

    # Log a debug message so that it can be returned in the response body if the user requested it
    #
    # === Parameters
    #
    # * +message+ - A message describing the debug information
    # * +type+ - The type of the message - should be a value in +DebugType+
    def log(message, type)
      @messages << ApiApe::ApeDebugLog.new(message, type)
    end

    # Log an info debug message that provides extra info to API consumers
    #
    # === Parameters
    #
    # * +message+ - A message describing the debug information
    def log_info(message)
      log(message, DebugType::INFO)
    end

    # Log a warning debug message that describes a non critical/error warning
    #
    # === Parameters
    #
    # * +message+ - A message describing the debug information
    def log_warning(message)
      log(message, DebugType::WARNING)
    end

    # Clears the log, removing all messages logged so far
    def clear_log
      @messages = []
    end

  end
end
