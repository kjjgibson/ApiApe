require 'rails_helper'
require 'api_ape/ape_renderer'

describe ApiApe::ApeRenderer do

  describe '#render_ape' do
    class DummyApeController < ApplicationController
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
        return [DummyNestedModel.new(1, 2, created_at: Date.current - 1.day), DummyNestedModel.new(3, 4, created_at: Date.current)]
      end

      def unorderable_association
        return [UnorderableModel.new(1), UnorderableModel.new(2)]
      end

    end

    class DummyNestedModel
      attr_accessor :nested_field1, :nested_field2, :created_at

      def initialize(nested_field1, nested_field2, created_at: nil)
        @nested_field1 = nested_field1
        @nested_field2 = nested_field2
        @created_at = created_at
      end

      def example_doubly_nested_association
        return DummyNestedModel.new(5, 6)
      end
    end

    class UnorderableModel
      attr_accessor :field

      def initialize(field)
        @field = field
      end
    end

    let(:controller) { DummyApeController.new }
    let(:ape_renderer) { ApiApe::ApeRenderer.new(permitted_fields) }
    let(:permitted_fields) { nil }

    context 'with fields param' do

      context 'single object' do
        let(:model) { DummyModel.new('Name', 'Description') }

        context 'with obj attributes' do
          let(:params) { { fields: 'name,description' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields requested' do
              expect(controller).to receive(:render).with(json: { name: 'Name', description: 'Description' })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'only one field permitted' do
            let(:permitted_fields) { [:name] }

            it 'should call render with the correct json including only permitted fields' do
              expect(controller).to receive(:render).with(json: { name: 'Name' })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'no fields permitted' do
            let(:permitted_fields) { [] }

            it 'should call render with the correct json including no fields' do
              expect(controller).to receive(:render).with(json: {})

              ape_renderer.render_ape(controller, params, model)
            end
          end
        end

        context 'with a single association' do
          let(:params) { { fields: 'example_single_association{nested_field1,nested_field2}' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields requested' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          nested_field1: 1, nested_field2: 2
                      }
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'both nested fields explicitly permitted' do
            let(:permitted_fields) { [example_single_association: [:nested_field1, :nested_field2]] }

            it 'should call render with the correct json including only permitted fields' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association: { nested_field1: 1, nested_field2: 2 }
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'one nested field not permitted' do
            let(:permitted_fields) { [example_single_association: :nested_field1] }

            it 'should call render with the correct json including only permitted fields' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association: { nested_field1: 1 }
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'no nested fields permitted' do
            let(:permitted_fields) { [:example_single_association] }

            it 'should call render with the correct json including only permitted fields' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association: {}
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'no fields permitted' do
            let(:permitted_fields) { [] }

            it 'should call render with the correct json including only permitted fields' do
              expect(controller).to receive(:render).with(json: {})

              ape_renderer.render_ape(controller, params, model)
            end
          end
        end

        context 'with a doubly nested single association' do
          let(:params) { { fields: 'example_single_association{nested_field1,nested_field2,example_doubly_nested_association{nested_field1,nested_field2}}' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields' do
              expect(controller).to receive(:render).with(json: {
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

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'with all fields explicitly permitted' do
            let(:permitted_fields) { [example_single_association: [:nested_field1, :nested_field2, example_doubly_nested_association: [:nested_field1, :nested_field2]]] }

            it 'should call render with the correct json including all fields' do
              expect(controller).to receive(:render).with(json: {
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

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'with one doubly nested field permitted' do
            let(:permitted_fields) { [example_single_association: [example_doubly_nested_association: :nested_field1]] }

            it 'should call render with the correct json including only the allowed fields' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          example_doubly_nested_association: { nested_field1: 5 }
                      }
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'with both double nested fields permitted' do
            let(:permitted_fields) { [example_single_association: [example_doubly_nested_association: [:nested_field1, :nested_field2]]] }

            it 'should call render with the correct json including only the allowed fields' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association:
                      {
                          example_doubly_nested_association: { nested_field1: 5, nested_field2: 6 }
                      }
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end

          context 'with the double nested association not permitted' do
            let(:permitted_fields) { [:example_single_association] }

            it 'should call render with the correct json including only the allowed fields' do
              expect(controller).to receive(:render).with(json: {
                  example_single_association: {}
              })

              ape_renderer.render_ape(controller, params, model)
            end
          end
        end

        context 'with a many association' do
          let(:params) { { fields: 'example_many_association{nested_field1,nested_field2}' } }

          it 'should call render with the correct json' do
            expect(controller).to receive(:render).with(json: {
                example_many_association: [
                    { nested_field1: 1, nested_field2: 2 },
                    { nested_field1: 3, nested_field2: 4 }
                ]
            })

            ape_renderer.render_ape(controller, params, model)
          end

          context 'with an association ordering' do
            let(:params) { { fields: "example_many_association{nested_field1,nested_field2}.order(#{ordering})" } }

            context 'chronological ordering' do
              let(:ordering) { 'chronological'}

              it 'should call render with the objects in chronological order' do
                expect(controller).to receive(:render).with(json: {
                    example_many_association: [
                        { nested_field1: 3, nested_field2: 4 },
                        { nested_field1: 1, nested_field2: 2 }
                    ]
                })

                ape_renderer.render_ape(controller, params, model)
              end
            end

            context 'reverse chronological ordering' do
              let(:ordering) { 'reverse_chronological'}

              it 'should call render with the objects in reverse chronological order' do
                expect(controller).to receive(:render).with(json: {
                    example_many_association: [
                        { nested_field1: 1, nested_field2: 2 },
                        { nested_field1: 3, nested_field2: 4 }
                    ]
                })

                ape_renderer.render_ape(controller, params, model)
              end
            end

            context 'invalid ordering string' do
              let(:ordering) { 'invalid_ordering'}

              it 'should call render with the objects in default order' do
                expect(controller).to receive(:render).with(json: {
                    example_many_association: [
                        { nested_field1: 1, nested_field2: 2 },
                        { nested_field1: 3, nested_field2: 4 }
                    ]
                })

                ape_renderer.render_ape(controller, params, model)
              end
            end

            context 'collection without created_at' do
              let(:params) { { fields: 'unorderable_association{field}.order(chronological)' } }

              it 'should call render with the objects in default order' do
                expect(controller).to receive(:render).with(json: {
                    unorderable_association: [
                        { field: 1 },
                        { field: 2 }
                    ]
                })

                ape_renderer.render_ape(controller, params, model)
              end
            end

            #TODO: working here ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          end
        end
      end

      context 'collection of objects' do
        let(:models) { [DummyModel.new('Name1', 'Description1'), DummyModel.new('Name2', 'Description2')] }

        context 'with obj attributes' do
          let(:params) { { fields: 'name,description' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields' do
              expect(controller).to receive(:render).with(json: [
                  { name: 'Name1', description: 'Description1' },
                  { name: 'Name2', description: 'Description2' }
              ])

              ape_renderer.render_ape(controller, params, models)
            end
          end

          context 'single field permitted' do
            let(:permitted_fields) { [:name] }

            it 'should call render with the correct json including only the permitted fields' do
              expect(controller).to receive(:render).with(json: [
                  { name: 'Name1' },
                  { name: 'Name2' }
              ])

              ape_renderer.render_ape(controller, params, models)
            end
          end
        end

        context 'with a single association' do
          let(:params) { { fields: 'example_single_association{nested_field1,nested_field2}' } }

          context 'permitted fields not specified' do
            it 'should call render with the correct json including all fields' do
              expect(controller).to receive(:render).with(json:
                                                              [{ example_single_association: { nested_field1: 1, nested_field2: 2 } },
                                                               { example_single_association: { nested_field1: 1, nested_field2: 2 } }
                                                              ])

              ape_renderer.render_ape(controller, params, models)
            end
          end

          context 'single nested field permitted' do
            let(:permitted_fields) { [example_single_association: :nested_field1] }

            it 'should call render with the correct json including only the permitted fields' do
              expect(controller).to receive(:render).with(json:
                                                              [{ example_single_association: { nested_field1: 1 } },
                                                               { example_single_association: { nested_field1: 1 } }
                                                              ])

              ape_renderer.render_ape(controller, params, models)
            end
          end
        end
      end
    end

    context 'without fields param' do
      let(:params) { {} }
      let(:model) { DummyModel.new('Name', 'Description') }
      let(:permitted_fields) { [] }

      it 'should call render' do
        expect(controller).to receive(:render).with(no_args())

        ape_renderer.render_ape(controller, params, model)
      end
    end

  end
end