require 'rails_helper'
require 'api_ape/ape_debugger'

describe ApiApe::ApeDebugger do

  before do
    ApiApe::ApeDebugger.instance.clear_log
  end

  after do
    ApiApe::ApeDebugger.instance.clear_log
  end

  describe '#log' do
    it 'should add a debug log to the messages' do
      message = 'my message'
      type = ApiApe::ApeDebugger::DebugType::INFO

      ApiApe::ApeDebugger.instance.log(message, type)

      debug_log = ApiApe::ApeDebugger.instance.messages.first
      expect(debug_log.message).to eq(message)
      expect(debug_log.type).to eq(type)
    end
  end

  describe '#log_info' do
    it 'should add a debug log to the messages' do
      message = 'my message'

      ApiApe::ApeDebugger.instance.log_info(message)

      debug_log = ApiApe::ApeDebugger.instance.messages.first
      expect(debug_log.message).to eq(message)
      expect(debug_log.type).to eq(ApiApe::ApeDebugger::DebugType::INFO)
    end
  end

  describe '#log_warning' do
    it 'should add a debug log to the messages' do
      message = 'my message'

      ApiApe::ApeDebugger.instance.log_warning(message)

      debug_log = ApiApe::ApeDebugger.instance.messages.first
      expect(debug_log.message).to eq(message)
      expect(debug_log.type).to eq(ApiApe::ApeDebugger::DebugType::WARNING)
    end
  end

  describe '#clear_log' do
    it 'should remove all messages logged' do
      ApiApe::ApeDebugger.instance.log_warning('message')

      ApiApe::ApeDebugger.instance.clear_log

      expect(ApiApe::ApeDebugger.instance.messages.count).to eq(0)
    end
  end

end