module ApiApe
  class ApeRenderer

    require 'api_ape/ape_metadata'
    require 'api_ape/ape_fields'
    require 'api_ape/ape_debugger'

    attr_reader :permitted_fields

    def initialize(permitted_fields)
      @permitted_fields = permitted_fields
      @response = nil
      @metadata = nil
      @debug_messages = nil
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
      set_response(params, render_target)
      set_metadata(params, render_target)
      set_debug_messages(params)

      render(controller)
    end

    # Setup the response instance variable if we are doing a custom render otherwise do nothing.
    # We'll do a custom render if we've been provided with the 'fields' query parameter in the request
    #
    # === Parameters
    #
    # * +params+ - The request params that might contain the 'fields' parameter
    # * +render_target+ - The object or collection that is used to get the fields
    private def set_response(params, render_target)
      if params[:fields].present?
        # If the request contained a "fields" query param then we need to
        #  construct the response JSON based on the fields that were asked for.
        @response = ApiApe::ApeFields.new(@permitted_fields).response_for_fields(render_target, params[:fields], @permitted_fields)
      else
        # If we didn't receive a "fields" query param then we can just do the default
        #  behaviour which is to just let the caller figure out what should be returned in the response
      end
    end

    # Update the current response with the metadata information if the metadata request flag was provided.
    # If the response is not set yet (in the case where the default render method will be called) then
    #  set the metadata instance variable so that it can be added after we call render.
    #
    # === Parameters
    #
    # * +params+ - The request params that might contain the 'metadata' flag
    private def set_metadata(params, render_target)
      if params[:metadata].present?
        metadata = ApiApe::ApeMetadata.new(render_target, @permitted_fields).metadata
        if @response
          # Merge in the metadata hash if we have a response hash already
          @response = @response.merge(metadata)
        else
          # If we don't have a response hash because the fields param wasn't supplied
          #  then we'll have to add the metadata after we call render and after the
          #  caller has decided what to put in the response body.
          @metadata = metadata
        end
      end
    end

    # Update the current response with potential debug information if the debug request param was provided.
    # If the response is not set yet (in the case where the default render method will be called) then
    #  set the debug messages instance variable so that it can be added after we call render.
    #
    # === Parameters
    #
    # * +params+ - The request params that might contain the 'debug' field
    private def set_debug_messages(params)
      debug_type = params[:debug]

      if debug_type.present?
        messages = []
        ApiApe::ApeDebugger.instance.messages.each do |log|
          # Only add the requests types into the array
          if debug_type == ApiApe::ApeDebugger::DebugType::ALL || log.type == debug_type
            messages << { message: log.message, type: log.type }
          end
        end

        debug_messages = { __debug__: { messages: messages } }

        if @response
          # Merge in the debug hash if we have a response hash already
          @response = @response.merge(debug_messages)
        else
          # If we don't have a response hash because the fields param wasn't supplied
          #  then we'll have to add the debug info after we call render and after the
          #  caller has decided what to put in the response body.
          @debug_messages = debug_messages
        end
      end
    end

    # Render a response depending on what query params the request contained.
    # If the response data is provided then return that, otherwise perform the default
    #  action by just calling render on the controller.
    #
    # === Parameters
    #
    # * +controller+ - The controller that's performing the rendering
    private def render(controller)
      if @response
        controller.send(:render, json: @response)
      else
        controller.send(:render)

        if @metadata
          add_hash_to_response(controller, @metadata, :metadata)
        end

        if @debug_messages
          add_hash_to_response(controller, @debug_messages, :debug)
        end

      end
    end

    # Add a hash to an already rendered response body by parsing it into a JSON object and then back again
    #
    # === Parameters
    #
    # * +controller+ - The controller that performed the rendering
    # * +hash+ - The hash to add to the response body
    # * +hash_data_type+ - The name of the type of data we're adding (used for debug messages)
    private def add_hash_to_response(controller, hash, hash_data_type)
      begin
        # Parse the current response body, merge in the hash, convert it back to JSON, and set it back on the response
        body = JSON.parse(controller.response.body)
        if body.is_a?(Hash)
          body.merge!(hash)

          controller.response.body = body.to_json
        else
          # If the body is a JSON Array and not an object then we can't add the hash to it
          ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.extra_data_for_json_array', extra_data_type: hash_data_type))
        end
      rescue JSON::ParserError => e
        # The response is not returning JSON so we can't add the hash
        ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.extra_data_for_non_json', extra_data_type: hash_data_type))
      end
    end

  end
end