require 'rails_helper'
require 'api_ape/ape_renderer'
require 'api_ape/ape_debugger'

describe ApiApe::ApeRenderer do

  describe '#render_ape' do
    let(:controller) { double('controller') }
    let(:ape_renderer) { ApiApe::ApeRenderer.new(permitted_fields) }
    let(:permitted_fields) { [:field1, :field2] }

    before do
      allow(controller).to receive(:render)
    end

    context 'with fields param' do
      let(:fields) { 'field1,field2' }
      let(:params) { { fields: fields } }
      let(:model) { double('model') }
      let(:response_hash) { { field1: :field1_value, field2: :field2_value } }

      before do
        allow_any_instance_of(ApiApe::ApeFields).to receive(:response_for_fields).and_return(response_hash)
      end

      it 'should call the ape fields with the correct params' do
        expect_any_instance_of(ApiApe::ApeFields).to receive(:response_for_fields).with(model, fields, permitted_fields)

        ape_renderer.render_ape(controller, params, model)
      end

      it 'should call render with the correct response' do
        expect(controller).to receive(:render).with({ json: response_hash })

        ape_renderer.render_ape(controller, params, model)
      end

      context 'with metadata param' do
        let(:params) { { fields: fields, metadata: 'true' } }
        let(:metadata) { { metadata: { fields: [:field1], associations: [:association1] } } }

        before do
          allow_any_instance_of(ApiApe::ApeMetadata).to receive(:metadata).and_return(metadata)
        end

        it 'should merge the metadata into the response' do
          expect(controller).to receive(:render).with({ json: response_hash.merge(metadata) })

          ape_renderer.render_ape(controller, params, model)
        end
      end
    end

    context 'without fields param' do
      let(:params) { {} }
      let(:model) { double('model') }
      let(:response_hash) { { field1: :field1_value, field2: :field2_value } }

      it 'should not call the ape fields' do
        expect_any_instance_of(ApiApe::ApeFields).not_to receive(:response_for_fields)

        ape_renderer.render_ape(controller, params, model)
      end

      it 'should call render with no response params' do
        expect(controller).to receive(:render).with(no_args)

        ape_renderer.render_ape(controller, params, model)
      end

      context 'with metadata param' do
        let(:params) { { metadata: 'true' } }
        let(:metadata) { { fields: [:field1], associations: [:association1] } }
        let(:response_double) { double('response') }

        before do
          allow_any_instance_of(ApiApe::ApeMetadata).to receive(:metadata).and_return({ metadata: metadata })
          allow(controller).to receive(:response).and_return(response_double)
          allow(response_double).to receive(:body).and_return(response_body)
        end

        context 'response body is a json object' do
          let(:response_body) { { field: :value }.to_json }

          it 'should merge the metadata into the response' do
            expect(response_double).to receive(:body=).with({ field: :value, metadata: metadata }.to_json)

            ape_renderer.render_ape(controller, params, model)
          end
        end

        context 'response body is a json array' do
          let(:response_body) { [{ field: :value }].to_json }

          before do
            allow(ApiApe::ApeDebugger.instance).to receive(:log_warning)
          end

          it 'should not change the response body' do
            expect(response_double).not_to receive(:body=)

            ape_renderer.render_ape(controller, params, model)
          end

          it 'should log a warning' do
            expect(ApiApe::ApeDebugger.instance).to receive(:log_warning).with(I18n.t('api_ape.debug.warning.metadata_for_json_array'))

            ape_renderer.render_ape(controller, params, model)
          end
        end

        context 'response body is not json' do
          let(:response_body) { 'invalid_json' }

          before do
            allow(ApiApe::ApeDebugger.instance).to receive(:log_warning)
          end

          it 'should not change the response body' do
            expect(response_double).not_to receive(:body=)

            ape_renderer.render_ape(controller, params, model)
          end

          it 'should log a warning' do
            expect(ApiApe::ApeDebugger.instance).to receive(:log_warning).with(I18n.t('api_ape.debug.warning.metadata_for_non_json'))

            ape_renderer.render_ape(controller, params, model)
          end
        end
      end
    end

  end
end