require 'rails_helper'
require 'api_ape/ape_debug_log'

describe ApiApe::ApeDebugLog do

  describe '#message' do
    it 'should return the message' do
      message = 'my message'
      expect(ApiApe::ApeDebugLog.new(message, nil).message).to eq(message)
    end
  end

  describe '#type' do
    it 'should return the type' do
      type = 'info'
      expect(ApiApe::ApeDebugLog.new(nil, type).type).to eq(type)
    end
  end

end