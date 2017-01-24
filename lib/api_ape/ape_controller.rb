module ApiApe
  module ApeController

    attr_reader :permitted_fields

    def permitted_fields(fields)
      @permitted_fields = fields
    end

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

    private def response_for_fields(obj, fields_string, root_permitted_field)
              # If we have a collection of objects then iterate over each of them
      if obj.respond_to?(:each)
        response = []
        obj.each do |o|
          response << fields_hash_for_object(o, fields_string, root_permitted_field)
        end
      else
        response = fields_hash_for_object(obj, fields_string, root_permitted_field)
      end

      return response
    end

    private def fields_hash_for_object(obj, fields_string, root_permitted_field)
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

          if is_field_permitted?(root_permitted_field, field)
            response[field] = response_for_fields(nested_obj, nested_fields_string, root_for_field(root_permitted_field, field))
          else
            #TODO: should log an error
          end
        else
          if is_field_permitted?(root_permitted_field, field)
            response[field] = obj.send(field)
          else
            #TODO: should log an error
          end
        end
      end

      return response
    end

    private def root_for_field(root_permitted_field, field)
      if root_permitted_field
        new_root = root_permitted_field.last
        if new_root.is_a?(Hash)
          new_root = new_root[field.to_sym]
        else
          new_root = []
        end
      else
        new_root = nil
      end

      return new_root
    end

    private def is_field_permitted?(root_permitted_fields, field)
      permitted = false
      field = field.to_sym
      # root_permitted_field = root_permitted_field.to_sym if root_permitted_field.is_a?(String)

      if @permitted_fields == nil
        permitted = true
      else
        if root_permitted_fields.respond_to?(:each)
          root_permitted_fields.each do |permitted_field|
            if permitted_field.is_a?(Hash)
              permitted = is_hash_field_permitted?(root_permitted_fields, field, permitted_field)
            else
              permitted = permitted_field == field
            end

            break if permitted
          end
        else
          permitted = root_permitted_fields == field
        end
      end

      return permitted
    end

    private def is_hash_field_permitted?(root_permitted_fields, field, permitted_field)
      if permitted_field.is_a?(Hash)
        permitted = permitted_field.key?(field)
      end
      # if root_permitted_fields
      # val = permitted_field[root_permitted_field]
      # if val.respond_to?(:each)
      #   permitted = val.include?(field)
      # else
      #   permitted = val == field
      # end
      # else
      #   permitted = permitted_field.key?(field.to_sym)
      # end

      return permitted
    end

  end
end