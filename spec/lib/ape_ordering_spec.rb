require 'rails_helper'
require 'api_ape/ape_ordering'

describe ApiApe::ApeOrdering do

  let(:ape_ordering) { ApiApe::ApeOrdering.new }

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
        expect(ape_ordering.order_collection([], nil)).to eq([])
      end
    end

    context 'unorderable collection' do
      it 'should return the collection' do
        expect(ape_ordering.order_collection('not_a_collection', nil)).to eq('not_a_collection')
      end
    end

    context 'active record association' do
      it 'should order the collection' do
        collection = double('collection')

        allow(collection).to receive(:respond_to?).with(:order).and_return(true)
        expect(collection).to receive(:order).with(created_at: :asc)

        ape_ordering.order_collection(collection, :asc)
      end
    end

    context 'array collection' do
      context 'descending order' do
        it 'should sort the array' do
          collection = double('collection')

          allow(collection).to receive(:respond_to?).with(:order).and_return(false)
          allow(collection).to receive(:respond_to?).with(:each).and_return(true)
          expect(collection).to receive(:sort_by!)

          ape_ordering.order_collection(collection, :desc)
        end
      end

      context 'ascending order' do
        it 'should sort the array' do
          collection = double('collection')

          allow(collection).to receive(:respond_to?).with(:order).and_return(false)
          allow(collection).to receive(:respond_to?).with(:each).and_return(true)
          expect(collection).to receive(:sort_by!)
          expect(collection).to receive(:reverse!)

          ape_ordering.order_collection(collection, :asc)
        end
      end
    end
  end

end