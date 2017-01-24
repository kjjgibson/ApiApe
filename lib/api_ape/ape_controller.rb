module ApiApe
  module ApeController

    attr_reader :permitted_fields

    def permitted_fields(fields)
      @permitted_fields = fields
    end

    # Render a response for an object.
    # If the "filter" query param is present in the request then a json response
    #   is constructed based on the requested fields.
    # If not then the render method is called and nothing else is done.
    #
    # === Parameters
    #
    # * +obj+ - The object to render
    def render_ape(obj)
      fields_param = params[:fields]

      if fields_param.present?
        # If the request contained a "fields" query param then we need to
        #  construct the response JSON based on the fields that were asked for.
        response = response_for_fields(obj, fields_param, @permitted_fields)

        render json: response
      else
        # If we didn't receive a "fields" query param then we can just do the default
        #  behaviour which is to just call render and let the caller figure out what should be rendered
        render
      end
    end

    # Returns a Hash of fields for a particular object or collection of objects
    #
    # === Parameters
    #
    # * +obj+ - The object or collection of objects from where the fields should be retrieved
    # * +fields_string+ - A string describing the fields that have been requested
    # * +permitted_fields+ - An array containing the fields that are permitted to be included in the response (potentially nil)
    private def response_for_fields(obj, fields_string, permitted_fields)
              # If we have a collection of objects then iterate over each of them
      if obj.respond_to?(:each)
        response = []
        obj.each do |o|
          response << fields_hash_for_object(o, fields_string, permitted_fields)
        end
      else
        response = fields_hash_for_object(obj, fields_string, permitted_fields)
      end

      return response
    end

    # Returns a Hash of fields for a particular object +obj+
    # If no permitted fields have been specified then all fields contained in the +field_string+ will be included
    # The fields are requested in the form of a string with the format:
    #   field1,field2,field3{nested_field1,nested_field2}
    #
    # === Parameters
    #
    # * +obj+ - The object from where the fields should be retrieved
    # * +fields_string+ - A string describing the fields that have been requested
    # * +permitted_fields+ - An array containing the fields that are permitted to be included in the response (potentially nil)
    private def fields_hash_for_object(obj, fields_string, permitted_fields)
              # Split the string by comma (but ignore commas inside curly braces)
              # E.g. "cool,awesome{nice,wow},yay" => ["cool", "awesome{nice,wow}", "yay"]
      fields = fields_string.scan(Regexp.new('((?>[^,{]+|({(?>[^{}]+|\g<-1>)*}))+)')).map(&:first)
      # (                 # first capturing group
      #   (?>             # open an atomic group (like a non capturing group)
      #     [^,{]+        # all characters except , and {
      #    |              # or
      #     (             # open the second capturing group
      #       {           # {
      #       (?>         # open a second atomic group
      #         [^{}]+    # all characters except braces
      #        |          # OR
      #         \g<-1>    # the last capturing group (you can write \g<2>)
      #       )*          # close the second atomic group
      #       \}          # }
      #     )             # close the second capturing group
      #   )+              # close the first atomic group and repeat it
      # )                 # close the first capturing group

      response = HashWithIndifferentAccess.new

      # Get the value of each field from the object
      fields.each do |field|
        # Look for nested fields which will be present inside curly braces
        # E.g. "field{nested_field}" => "nested_field"
        nested_fields_string = field.match(/({(.*)})/).try(:[], 2)

        # Get the top level field without the nested fields on the end
        # E.g. "field{nested_field}" => "field"
        field = field.split(/{.*}/)[0]

        # If we found any nested fields then we'll need to recursively get their values
        #  otherwise we'll just use send() to get the value on the current object
        if nested_fields_string
          # Get the object that the nested fields should be called on
          nested_obj = obj.send(field)

          if is_field_permitted?(permitted_fields, field)
            response[field] = response_for_fields(nested_obj, nested_fields_string, root_for_field(permitted_fields, field))
          else
            #TODO: add warning to debug object
          end
        else
          if is_field_permitted?(permitted_fields, field)
            response[field] = obj.send(field)
          else
            #TODO: add warning to debug object
          end
        end
      end

      return response
    end

    # Returns a root object for a particular field
    #
    # E.g.
    #
    # root_for_field([field, association: :nested_field], :association)   # =>  { association: :nested_field }
    # root_for_field([field], :field)                                     # => nil
    # root_for_field(nil, :field)                                         # => nil
    #
    # === Parameters
    #
    # * +permitted_fields+ - An array of permitted fields used to find the +field+
    # * +field+ - A field to find in the +permitted_fields+ array
    private def root_for_field(permitted_fields, field)
      if permitted_fields
        # The last element of the permitted_fields array may potentially be a hash containing any nested fields
        new_root = permitted_fields.last
        if new_root.is_a?(Hash)
          new_root = new_root[field.to_sym]
        else
          # If we didn't find a hash field then there is no root for this field
          new_root = nil
        end
      else
        new_root = nil
      end

      return new_root
    end

    # Returns true if a specific field is permitted
    # If no fields have been explicitly permitted then all fields will return true
    # Otherwise only fields that are specified with be permitted
    #
    # === Parameters
    #
    # * +permitted_fields+ - An array or symbol which describes the current permitted fields
    # * +field+ - A string or symbol which is the field name
    private def is_field_permitted?(permitted_fields, field)
      permitted = false
      field = field.to_sym

      # By default we always permit all fields if none have been explicitly permitted
      if @permitted_fields == nil
        permitted = true
      else

        # We might have an array or just a symbol so we need to check
        # E.g. [association: :field] or [association: [:field1, :field2]]
        if permitted_fields.respond_to?(:each)
          permitted_fields.each do |permitted_field|
            if permitted_field.is_a?(Hash)
              permitted = permitted_field.key?(field)
            else
              permitted = permitted_field == field
            end

            # Once we've determined that the field is permitted then we don't need to check the rest of the fields
            break if permitted
          end
        else
          permitted = permitted_fields == field
        end
      end

      return permitted
    end

  end
end