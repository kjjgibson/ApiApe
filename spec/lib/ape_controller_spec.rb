require 'rails_helper'
require 'api_ape/ape_controller'

describe ApiApe::ApeController, type: :controller do

  describe '#render_ape' do
    class DummyApeController < ApplicationController
      include ApiApe::ApeController
    end

    class DummyModel
      attr_accessor :name, :description

      def initialize(name, description)
        @name = name
        @description = description
      end

      def example_single_association
        return DummyNestedModel.new(1, 2)
      end

      def example_many_association
        return [DummyNestedModel.new(1, 2), DummyNestedModel.new(3, 4)]
      end

    end

    class DummyNestedModel
      attr_accessor :nested_field1, :nested_field2

      def initialize(nested_field1, nested_field2)
        @nested_field1 = nested_field1
        @nested_field2 = nested_field2
      end

      def example_doubly_nested_association
        return DummyNestedModel.new(5, 6)
      end
    end

    let(:ape_controller) { DummyApeController.new }

    before do
      allow(ape_controller).to receive(:params).and_return(params)
    end

    context 'with fields param' do

      context 'single object' do
        let(:model) { DummyModel.new('Name', 'Description') }

        context 'with obj attributes' do
          let(:params) { { fields: 'name,description' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields requested' do
              expect(ape_controller).to receive(:render).with(json: { name: 'Name', description: 'Description' })

              ape_controller.render_ape(model)
            end
          end

          context 'only one field permitted' do
            before do
              ape_controller.permitted_fields([:name])
            end

            it 'should call render with the correct json including only permitted fields' do
              expect(ape_controller).to receive(:render).with(json: { name: 'Name' })

              ape_controller.render_ape(model)
            end
          end

          context 'no fields permitted' do
            before do
              ape_controller.permitted_fields([])
            end

            it 'should call render with the correct json including no fields' do
              expect(ape_controller).to receive(:render).with(json: {})

              ape_controller.render_ape(model)
            end
          end
        end

        context 'with a single association' do
          let(:params) { { fields: 'example_single_association{nested_field1,nested_field2}' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields requested' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          nested_field1: 1, nested_field2: 2
                      }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'both nested fields explicitly permitted' do
            before do
              ape_controller.permitted_fields([example_single_association: [:nested_field1, :nested_field2]])
            end

            it 'should call render with the correct json including only permitted fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association: { nested_field1: 1, nested_field2: 2 }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'one nested field not permitted' do
            before do
              ape_controller.permitted_fields([example_single_association: :nested_field1])
            end

            it 'should call render with the correct json including only permitted fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association: { nested_field1: 1 }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'no nested fields permitted' do
            before do
              ape_controller.permitted_fields([:example_single_association])
            end

            it 'should call render with the correct json including only permitted fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association: {}
              })

              ape_controller.render_ape(model)
            end
          end

          context 'no fields permitted' do
            before do
              ape_controller.permitted_fields([])
            end

            it 'should call render with the correct json including only permitted fields' do
              expect(ape_controller).to receive(:render).with(json: {})

              ape_controller.render_ape(model)
            end
          end
        end

        context 'with a doubly nested single association' do
          let(:params) { { fields: 'example_single_association{nested_field1,nested_field2,example_doubly_nested_association{nested_field1,nested_field2}}' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          nested_field1: 1,
                          nested_field2: 2,
                          example_doubly_nested_association:
                              {
                                  nested_field1: 5,
                                  nested_field2: 6
                              }
                      }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'with all fields explicitly permitted' do
            before do
              ape_controller.permitted_fields([example_single_association: [:nested_field1, :nested_field2, example_doubly_nested_association: [:nested_field1, :nested_field2]]])
            end

            it 'should call render with the correct json including all fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          nested_field1: 1,
                          nested_field2: 2,
                          example_doubly_nested_association:
                              {
                                  nested_field1: 5,
                                  nested_field2: 6
                              }
                      }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'with one doubly nested field permitted' do
            before do
              ape_controller.permitted_fields([example_single_association: [example_doubly_nested_association: :nested_field1]])
            end

            it 'should call render with the correct json including only the allowed fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          example_doubly_nested_association: { nested_field1: 5 }
                      }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'with both double nested fields permitted' do
            before do
              ape_controller.permitted_fields([example_single_association: [example_doubly_nested_association: [:nested_field1, :nested_field2]]])
            end

            it 'should call render with the correct json including only the allowed fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          example_doubly_nested_association: { nested_field1: 5, nested_field2: 6 }
                      }
              })

              ape_controller.render_ape(model)
            end
          end

          context 'with the double nested association not permitted' do
            before do
              ape_controller.permitted_fields([:example_single_association])
            end

            it 'should call render with the correct json including only the allowed fields' do
              expect(ape_controller).to receive(:render).with(json: {
                  example_single_association: {}
              })

              ape_controller.render_ape(model)
            end
          end
        end

        context 'with a many association' do
          let(:params) { { fields: 'example_many_association{nested_field1,nested_field2}' } }

          it 'should call render with the correct json' do
            expect(ape_controller).to receive(:render).with(json: {
                example_many_association: [
                    { nested_field1: 1, nested_field2: 2 },
                    { nested_field1: 3, nested_field2: 4 }
                ]
            })

            ape_controller.render_ape(model)
          end
        end
      end

      context 'collection of objects' do
        let(:models) { [DummyModel.new('Name1', 'Description1'), DummyModel.new('Name2', 'Description2')] }

        context 'with obj attributes' do
          let(:params) { { fields: 'name,description' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields' do
              expect(ape_controller).to receive(:render).with(json: [
                  { name: 'Name1', description: 'Description1' },
                  { name: 'Name2', description: 'Description2' }
              ])

              ape_controller.render_ape(models)
            end
          end

          context 'single field permitted' do
            before do
              ape_controller.permitted_fields([:name])
            end

            it 'should call render with the correct json including only the permitted fields' do
              expect(ape_controller).to receive(:render).with(json: [
                  { name: 'Name1' },
                  { name: 'Name2' }
              ])

              ape_controller.render_ape(models)
            end
          end
        end

        context 'with a single association' do
          let(:params) { { fields: 'example_single_association{nested_field1,nested_field2}' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields' do
              expect(ape_controller).to receive(:render).with(json:
                                                                  [{ example_single_association: { nested_field1: 1, nested_field2: 2 } },
                                                                   { example_single_association: { nested_field1: 1, nested_field2: 2 } }
                                                                  ])

              ape_controller.render_ape(models)
            end
          end

          context 'single nested field permitted' do
            before do
              ape_controller.permitted_fields([example_single_association: :nested_field1])
            end

            it 'should call render with the correct json including only the permitted fields' do
              expect(ape_controller).to receive(:render).with(json:
                                                                  [{ example_single_association: { nested_field1: 1 } },
                                                                   { example_single_association: { nested_field1: 1 } }
                                                                  ])

              ape_controller.render_ape(models)
            end
          end
        end
      end
    end

    context 'without fields param' do
      let(:params) { {} }
      let(:model) { DummyModel.new('Name', 'Description') }

      it 'should call render' do
        expect(ape_controller).to receive(:render).with(no_args())

        ape_controller.render_ape(model)
      end
    end

  end
end