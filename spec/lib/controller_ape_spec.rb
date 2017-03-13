require 'rails_helper'
require 'api_ape/controller_ape'

describe ApiApe::ControllerApe do

  #A Dummy controller that we can use to test the filters
  class DummyController
    def self.before_filter(*args)
      # Yield the block so that we can test it
      # This block would normally be tested when the Controller action is called
      yield DummyController.new
    end

    def self.prepend_before_filter(*args)
    end

    def self.around_filter(*args)
      # Yield the block so that we can test it
      # This block would normally be tested when the Controller action is called
      # The yield call will also pass the controller and a block (the actual controller action)
      #  so let's mock that by returning a Proc that executes a dummy method
      dummy = DummyController.new
      yield dummy, Proc.new { dummy.dummy_method }
    end

    def self.prepend_around_filter(*args)
    end

    def params
      {}
    end

    def dummy_method
    end
  end

  describe '.add_before_filter' do
    before do
      allow_any_instance_of(ApiApe::ControllerApe).to receive(:load_resource)
    end

    context 'prepend not specified' do
      context 'no extra args' do
        it 'should call the before_filter method on the class provided' do
          expect(DummyController).to receive(:before_filter).with({})

          ApiApe::ControllerApe.add_before_filter(DummyController, :load_resource)
        end

        it 'should call the method' do
          expect_any_instance_of(ApiApe::ControllerApe).to receive(:load_resource)

          ApiApe::ControllerApe.add_before_filter(DummyController, :load_resource)
        end
      end

      context 'extra args' do
        it 'should call the before_filter method with the args' do
          extra_args = { only: :only_value, except: :except_value, if: :if_value, unless: :unless_value }

          expect(DummyController).to receive(:before_filter).with(extra_args)

          ApiApe::ControllerApe.add_before_filter(DummyController, :load_resource, extra_args)
        end
      end

      context 'extra unexpected args' do
        it 'should call the before_filter method without the unexpected args args' do
          extra_args = { only: :only_value, unexpected: :spanish_inquisition }

          expect(DummyController).to receive(:before_filter).with({ only: :only_value })

          ApiApe::ControllerApe.add_before_filter(DummyController, :load_resource, extra_args)
        end
      end
    end

    context 'prepend specified' do
      it 'should call the before_filter method on the class provided' do
        expect(DummyController).to receive(:prepend_before_filter).with({})

        ApiApe::ControllerApe.add_before_filter(DummyController, :load_resource, prepend: true)
      end
    end
  end

  describe '.add_around_filter' do
    before do
      allow_any_instance_of(ApiApe::ControllerApe).to receive(:load_and_render_ape)
    end

    context 'prepend not specified' do
      context 'no extra args' do
        it 'should call the around_filter method on the class provided' do
          expect(DummyController).to receive(:around_filter).with({})

          ApiApe::ControllerApe.add_around_filter(DummyController, :load_and_render_ape)
        end

        it 'should call the method' do
          expect_any_instance_of(ApiApe::ControllerApe).to receive(:load_and_render_ape)

          ApiApe::ControllerApe.add_around_filter(DummyController, :load_and_render_ape)
        end

        it 'should execute the block when the method yields' do
          allow_any_instance_of(ApiApe::ControllerApe).to receive(:load_and_render_ape).and_yield
          expect_any_instance_of(DummyController).to receive(:dummy_method)

          ApiApe::ControllerApe.add_around_filter(DummyController, :load_and_render_ape)
        end
      end

      context 'extra args' do
        it 'should call the before_filter method with the args' do
          extra_args = { only: :only_value, except: :except_value, if: :if_value, unless: :unless_value }

          expect(DummyController).to receive(:around_filter).with(extra_args)

          ApiApe::ControllerApe.add_around_filter(DummyController, :load_and_render_ape, extra_args)
        end
      end

      context 'extra unexpected args' do
        it 'should call the before_filter method without the unexpected args args' do
          extra_args = { only: :only_value, unexpected: :spanish_inquisition }

          expect(DummyController).to receive(:around_filter).with({ only: :only_value })

          ApiApe::ControllerApe.add_around_filter(DummyController, :load_and_render_ape, extra_args)
        end
      end
    end

    context 'prepend specified' do
      it 'should call the before_filter method on the class provided' do
        expect(DummyController).to receive(:prepend_around_filter).with({})

        ApiApe::ControllerApe.add_around_filter(DummyController, :load_and_render_ape, prepend: true)
      end
    end
  end

end