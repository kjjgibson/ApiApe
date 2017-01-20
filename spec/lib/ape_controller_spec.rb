require 'rails_helper'
require 'api_ape/ape_controller'

describe ApiApe::ApeController, type: :controller do

  controller(ActionController::Base) do

    include ApiApe::ApeController
    before_filter :controller_before_filter

    def controller_before_filter
      puts 'controller_before_filter'
    end

    def show
      render json: { cool: :awesome }
    end
  end

  describe '#filter_params' do

    it 'should work' do
      get :show, id: 1
    end

  end

end