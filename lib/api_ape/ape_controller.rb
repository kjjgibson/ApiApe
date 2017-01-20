module ApiApe
  module ApeController

    def self.included(base)
      base.before_filter :process_request
    end

    private def process_request
      filter_params
    end

    private def filter_params
      puts 'filter_params'
    end

  end
end