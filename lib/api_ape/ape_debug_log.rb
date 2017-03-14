module ApiApe
  class ApeDebugLog

    attr_accessor :message, :type

    def initialize(message, type)
      @message = message
      @type = type
    end

  end
end
