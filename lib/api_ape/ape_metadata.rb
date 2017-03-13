module ApiApe
  # This class deals with collecting metadata about a particular Model
  #  so that it can be returned in the response body of a request
  #  when the request contains the metadata flag.
  # This is useful to allow an API consumer to self discover the API
  #  without needing to read API documentation.
  class ApeMetadata

    attr_reader :render_target, :permitted_fields

    def initialize(render_target, permitted_fields)
      @render_target = render_target
      @permitted_fields = permitted_fields
    end

    # Return a hash of metadata information about the @render_target
    # The hash contains two keys: fields and associations
    # If the @permitted_params are provided then only fields and associations
    #  contained will be added to the metadata hash.
    def metadata
      metadata_hash = {}

      fields = fields_for_target()
      metadata_hash[:fields] = fields if fields && fields.count > 0

      associations = associations_for_target()
      metadata_hash[:associations] = associations if associations && associations.count > 0

      return { metadata: metadata_hash }
    end

    # Return an array of names of columns on the @render_target
    # If the @permitted_fields are provided then only fields provided are returned
    private def fields_for_target
      fields = nil

      if @permitted_fields
        fields = @permitted_fields.select { |f| f.class == String || f.class == Symbol }
      else
        clazz = class_for_target()
        fields = clazz.column_names if clazz
      end

      return fields
    end

    # Return an array of names of associations on the @render_target
    # If the @permitted_fields are provided then only associations provided are returned
    private def associations_for_target
      associations = nil

      if @permitted_fields
        # If there are associations then they will be defined in a hash as the last element of the array
        associations_hash = @permitted_fields[-1]

        if associations_hash.is_a?(Hash)
          associations = associations_hash.keys
        else
          # There are no associations defined in the @permitted_fields
          associations = nil
        end
      else
        clazz = class_for_target()
        associations = clazz.reflect_on_all_associations.map(&:name) if clazz
      end

      return associations
    end

    # The @render_target may be an ActiveRecordAssociation so we need to
    #  get the model class (without causing the statement to be executed)
    #
    # Return the @render_target class if it's not an association otherwise
    #  return the class of the model backing the association
    private def class_for_target
      if @render_target.respond_to?(:model)
        model_class = @render_target.model
      elsif @render_target.is_a?(Array) && @render_target.count > 0
        model_class = @render_target[0].class
      else
        model_class = @render_target.class
      end

      return model_class
    end

  end
end