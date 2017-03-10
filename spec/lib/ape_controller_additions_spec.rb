require 'rails_helper'
require 'api_ape/ape_controller_additions'
require 'api_ape/controller_ape'

describe ApiApe::ApeControllerAdditions do

  let(:controller_additions) { ActionController::Base.new { include ApiApe::ApeControllerAdditions } }

  describe 'class methods' do
    it 'should include all class methods' do
      expect(controller_additions.class).to respond_to(:load_and_render_ape)
      expect(controller_additions.class).to respond_to(:load_resource)
      expect(controller_additions.class).to respond_to(:render_ape)
      expect(controller_additions.class).to respond_to(:skip_load_and_render_ape)
      expect(controller_additions.class).to respond_to(:skip_load_resource)
      expect(controller_additions.class).to respond_to(:skip_render_ape)
    end
  end

  describe '.load_and_render_ape' do
    it 'should call the ControllerApe to add a filter' do
      expect(ApiApe::ControllerApe).to receive(:add_around_filter).with(controller_additions.class, :load_and_render_ape, arg: 'Aaargh!')

      controller_additions.class.load_and_render_ape(arg: 'Aaargh!')
    end
  end

  describe '.load_resource' do
    it 'should call the ControllerApe to add a filter' do
      expect(ApiApe::ControllerApe).to receive(:add_before_filter).with(controller_additions.class, :load_resource, arg: 'Aaargh!')

      controller_additions.class.load_resource(arg: 'Aaargh!')
    end
  end

  describe '.render_ape' do
    it 'should call the ControllerApe to add a filter' do
      expect(ApiApe::ControllerApe).to receive(:add_around_filter).with(controller_additions.class, :render_ape, arg: 'Aaargh!')

      controller_additions.class.render_ape(arg: 'Aaargh!')
    end
  end

  describe '.skip_load_and_render_ape' do
    before do
      controller_additions.class.instance_variable_set(:@_ape_skipper, nil)
    end

    it 'should update the ape_skipper' do
      controller_additions.class.skip_load_and_render_ape('action_name', only: :index)

      expect(controller_additions.class.ape_skipper.deep_symbolize_keys).to eq({ load: { action_name: { only: :index } }, render: { action_name: { only: :index } } })
    end
  end

  describe '.skip_load_resource' do
    before do
      controller_additions.class.instance_variable_set(:@_ape_skipper, nil)
    end

    it 'should update the ape_skipper' do
      controller_additions.class.skip_load_resource('action_name', only: :index)

      expect(controller_additions.class.ape_skipper.deep_symbolize_keys).to eq({ load: { action_name: { only: :index } }, render: {} })
    end
  end

  describe '.skip_render_ape' do
    before do
      controller_additions.class.instance_variable_set(:@_ape_skipper, nil)
    end

    it 'should update the ape_skipper' do
      controller_additions.class.skip_render_ape('action_name', only: :index)

      expect(controller_additions.class.ape_skipper.deep_symbolize_keys).to eq({ render: { action_name: { only: :index } }, load: {} })
    end
  end

  describe '#render_ape' do
    let(:object_to_render) { double('object_to_render') }
    let(:params) { { param1: 'Param1' } }

    before do
      allow(controller_additions).to receive(:params).and_return(params)
    end

    context 'no args' do
      context 'class permitted_fields is nil' do
        it 'should call the render_ape method' do
          expect_any_instance_of(ApiApe::ApeRenderer).to receive(:render_ape).with(controller_additions, params, object_to_render)

          controller_additions.render_ape(object_to_render)
        end
      end

      context 'class permitted_fields is not nil' do
        before do
          controller_additions.class.permitted_ape_fields([:title, :description])
        end

        it 'should use the class permitted fields' do
          expect(ApiApe::ApeRenderer).to receive(:new).with([:title, :description]).and_call_original
          expect_any_instance_of(ApiApe::ApeRenderer).to receive(:render_ape).with(controller_additions, params, object_to_render)

          controller_additions.render_ape(object_to_render)
        end
      end
    end

    context 'with permitted_fields arg' do
      context 'class permitted_fields is nil' do
        it 'should use the permitted fields' do
          expect(ApiApe::ApeRenderer).to receive(:new).with([:title]).and_call_original
          expect_any_instance_of(ApiApe::ApeRenderer).to receive(:render_ape).with(controller_additions, params, object_to_render)

          controller_additions.render_ape(object_to_render, permitted_fields: [:title])
        end
      end

      context 'class permitted_fields is not nil' do
        before do
          controller_additions.class.permitted_ape_fields([:title, :description])
        end

        it 'should use the permitted fields passed in' do
          expect(ApiApe::ApeRenderer).to receive(:new).with([:title]).and_call_original
          expect_any_instance_of(ApiApe::ApeRenderer).to receive(:render_ape).with(controller_additions, params, object_to_render)

          controller_additions.render_ape(object_to_render, permitted_fields: [:title])
        end
      end
    end
  end

end