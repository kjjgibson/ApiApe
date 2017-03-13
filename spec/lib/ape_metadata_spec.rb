require 'rails_helper'
require 'api_ape/ape_metadata'

describe ApiApe::ApeMetadata do

  describe '#metadata' do
    let(:ape_metadata) { ApiApe::ApeMetadata.new(render_target, permitted_fields) }

    class DummyRenderTarget

      class Association
        attr_reader :name

        def initialize(name)
          @name = name
        end
      end

      def self.column_names
        return [:column1, :column2]
      end

      def self.reflect_on_all_associations
        return [Association.new(:association1), Association.new(:association2)]
      end

    end

    context 'no permitted fields' do
      let(:permitted_fields) { nil }

      context 'single object' do
        let(:render_target) { DummyRenderTarget.new }

        it 'should return the fields and associations' do
          expect(ape_metadata.metadata).to eq({ metadata: { fields: [:column1, :column2], associations: [:association1, :association2] } })
        end
      end

      context 'collection of objects' do
        let(:render_target) { double('association') }

        before do
          allow(render_target).to receive(:model).and_return(DummyRenderTarget)
        end

        it 'should return the fields and associations of the object in the collection' do
          expect(ape_metadata.metadata).to eq({ metadata: { fields: [:column1, :column2], associations: [:association1, :association2] } })
        end
      end
    end

    context 'permitted fields' do
      let(:render_target) { DummyRenderTarget.new }

      context 'no associations' do
        let(:permitted_fields) { [:column1, :column2] }

        it 'should return the correct permitted fields and associations' do
          expect(ape_metadata.metadata).to eq({ metadata: { fields: [:column1, :column2] } })
        end
      end

      context 'no fields' do
        let(:permitted_fields) { [association1: :association1_column1,
                                  association2: [:association2_column1, :association2_column2]] }

        it 'should return the correct permitted fields and associations' do
          expect(ape_metadata.metadata).to eq({ metadata: { associations: [:association1, :association2] } })
        end
      end

      context 'with associations' do
        let(:permitted_fields) { [:column1, :column2,
                                  association1: :association1_column1,
                                  association2: [:association2_column1, :association2_column2]] }

        it 'should return the correct permitted fields and associations' do
          expect(ape_metadata.metadata).to eq({ metadata: { fields: [:column1, :column2], associations: [:association1, :association2] } })
        end
      end
    end
  end

end