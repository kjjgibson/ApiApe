require 'rails_helper'
require 'api_ape/ape_ordering'
require 'api_ape/ape_debugger'

describe ApiApe::ApeOrdering do

  let(:ape_ordering) { ApiApe::ApeOrdering.new }

  before do
    allow(ApiApe::ApeDebugger.instance).to receive(:log_warning)
  end

  describe '#order_direction_for_field' do
    context 'no order clause' do
      it 'should return nil' do
        expect(ape_ordering.order_direction_for_field('no_order_clause')).to eq(nil)
      end
    end

    context 'invalid order clause' do
      it 'should return nil' do
        expect(ape_ordering.order_direction_for_field('field.order(')).to eq(nil)
        expect(ape_ordering.order_direction_for_field('field.order(invalid)')).to eq(nil)
      end

      it 'should log a warning' do
        expect(ApiApe::ApeDebugger.instance).to receive(:log_warning).with(I18n.t('api_ape.debug.warning.invalid_nested_field_ordering')).twice

        ape_ordering.order_direction_for_field('field.order(')
        ape_ordering.order_direction_for_field('field.order(invalid)')
      end
    end

    context 'with an order clause' do
      it 'should return the correct order' do
        expect(ape_ordering.order_direction_for_field('field.order(chronological)')).to eq(:asc)
        expect(ape_ordering.order_direction_for_field('field.order(reverse_chronological)')).to eq(:desc)
      end
    end
  end

  describe 'order_collection' do
    context 'no order direction' do
      it 'should return the collection' do
        expect(ape_ordering.order_collection([], :created_at, nil)).to eq([])
      end
    end

    context 'unorderable collection' do
      it 'should return the collection' do
        expect(ape_ordering.order_collection('not_a_collection', :created_at, :asc)).to eq('not_a_collection')
      end

      it 'should log a warning' do
        expect(ApiApe::ApeDebugger.instance).to receive(:log_warning).with(I18n.t('api_ape.debug.warning.unorderable_collection'))

        ape_ordering.order_collection('not_a_collection', :created_at, :asc)
      end
    end

    context 'active record association' do
      let(:collection) { double('collection') }
      let(:model) { double('model') }

      before do
        allow(collection).to receive(:respond_to?).with(:order).and_return(true)
        allow(collection).to receive(:model).and_return(model)
        allow(model).to receive(:column_names).and_return(['created_at'])
      end

      it 'should order the collection' do
        expect(collection).to receive(:order).with(created_at: :asc)

        ape_ordering.order_collection(collection, :created_at, :asc)
      end

      context 'association models do not respond to created_at' do
        before do
          allow(model).to receive(:column_names).and_return([])
        end

        it 'should log a warning' do
          expect(collection).not_to receive(:order).with(created_at: :asc)
          expect(ApiApe::ApeDebugger.instance).to receive(:log_warning).with(I18n.t('api_ape.debug.warning.invalid_order_field'))

          ape_ordering.order_collection(collection, :created_at, :asc)
        end
      end
    end

    context 'array collection' do
      let(:collection) { double('collection') }

      before do
        allow(collection).to receive(:respond_to?).with(:order).and_return(false)
        allow(collection).to receive(:respond_to?).with(:each).and_return(true)
      end

      context 'descending order' do
        it 'should sort the array' do
          expect(collection).to receive(:sort_by!)

          ape_ordering.order_collection(collection, :created_at, :desc)
        end

        context 'array of objects that do not respond to created_at' do
          it 'should log a warning' do
            expect(collection).to receive(:sort_by!).and_raise(NoMethodError)
            expect(ApiApe::ApeDebugger.instance).to receive(:log_warning).with(I18n.t('api_ape.debug.warning.invalid_order_field'))

            ape_ordering.order_collection(collection, :created_at, :desc)
          end
        end
      end

      context 'ascending order' do
        it 'should sort the array' do
          expect(collection).to receive(:sort_by!)
          expect(collection).to receive(:reverse!)

          ape_ordering.order_collection(collection, :created_at, :asc)
        end
      end
    end
  end

end