module ApiApe
  class ApeRenderer

    require 'api_ape/ape_metadata'
    require 'api_ape/ape_fields'
    require 'api_ape/ape_debugger'

    attr_reader :permitted_fields

    def initialize(permitted_fields)
      @permitted_fields = permitted_fields
    end

    # Render a response for an object.
    # If the "filter" query param is present in the request then a json response
    #   is constructed based on the requested fields.
    # If not then the render method is called and nothing else is done.
    #
    # === Parameters
    #
    # * +controller+ - The Controller which to call render on
    # * +params+ - A hash of params that should contain a :fields key
    # * +render_target+ - An object that should respond to the fields requested
    def render_ape(controller, params, render_target)
      # By default we'll set the response to nil and if it's still nil
      #  at the end then we'll just do the default render call
      response = nil
      metadata = nil
      fields_param = params[:fields]

      if fields_param.present?
        # If the request contained a "fields" query param then we need to
        #  construct the response JSON based on the fields that were asked for.
        response = ApiApe::ApeFields.new(@permitted_fields).response_for_fields(render_target, fields_param, @permitted_fields)
      else
        # If we didn't receive a "fields" query param then we can just do the default
        #  behaviour which is to just let the caller figure out what should be returned in the response
      end

      if params[:metadata].present?
        metadata = ApiApe::ApeMetadata.new(render_target, @permitted_fields).metadata
        if response
          # Merge in the metadata hash if we have a response hash already
          response = response.merge(metadata)
        else
          # If we don't have a response hash because the fields param wasn't supplied
          #  then we'll have to add the metadata after we call render and after the
          #  caller has decided what to put in the response body.
        end
      end

      render(controller, response, metadata)
    end

    # Render a response depending on what query params the request contained.
    # If the response data is provided then return that, otherwise perform the default
    #  action by just calling render on the controller.
    #
    # === Parameters
    #
    # * +controller+ - The controller that's performing the rendering
    # * +response+ - An option hash of response data
    # * +metadata+ - An optional hash of metadata information to add to the response
    private def render(controller, response, metadata)
      if response
        controller.send(:render, json: response)
      else
        controller.send(:render)

        if metadata
          # Add the metadata to the response after the default render call has been made
          begin
            # Parse the current response body, merge in the metadata, convert it back to JSON, and set it back on the response
            body = JSON.parse(controller.response.body)
            if body.is_a?(Hash)
              body.merge!(metadata)

              controller.response.body = body.to_json
            else
              # If the body is a JSON Array and not an object then we can't add the metadata to it
              ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.metadata_for_json_array'))
            end
          rescue JSON::ParserError => e
            # The response is not returning JSON so we can't add the metadata
            ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.metadata_for_non_json'))
          end
        end
      end
    end

  end
end