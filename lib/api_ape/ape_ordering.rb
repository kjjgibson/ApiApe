module ApiApe
  class ApeOrdering

    require 'api_ape/ape_debugger'

    module OrderTypes
      CHRONOLOGICAL = :chronological
      REVERSE_CHRONOLOGICAL = :reverse_chronological
    end

    # Return an order direction (:asc or :desc) based on a field string
    # The field string should be in the format field.order(chronological|reverse_chronological)
    # If there is no order section or if the text inside the parenthesis does not match a known value
    #  then the order direction returned will be nil
    #
    # === Parameters
    #
    # * +field+ - A field string that may optionally contain an order clause
    def order_direction_for_field(field)
      order_direction = nil

      # Split the field on a "." to see if there's an ordering specified
      # Ordering's are specified like: field.order(chronological|reverse_chronological)
      order_string = field.split('.').try(:[], 1)

      if order_string.present?
        # Get the string between the parenthesis to get the order direction
        order_type = order_string.match(/(\((.*)\))/).try(:[], 2)
        if order_type.try(:to_sym) == OrderTypes::CHRONOLOGICAL
          order_direction = :asc
        elsif order_type.try(:to_sym) == OrderTypes::REVERSE_CHRONOLOGICAL
          order_direction = :desc
        else
          ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.invalid_nested_field_ordering'))
        end
      end

      return order_direction
    end

    # Optionally order a collection of objects if an +order_direction+ is provided
    # If the collection responds to order() (i.e. an ActiveRecordRelation) then it is ordered using that method
    # Otherwise if it responds to each() then it is sorted in memory using sort_by()
    # If the collection responds to neither then it is not changed.
    #
    # If the objects in the collection do not respond to created_at then the collection is unchanged.
    #
    # === Parameters
    #
    # * +collection+ - A collection of objects (should respond to each() or order())
    # * +order_field+ - The field by which to order the collection
    # * +order_direction+ - An order direction (either :desc or :asc)
    def order_collection(collection, order_field, order_direction)
      if [:asc, :desc].include?(order_direction.try(:to_sym))
        if collection.respond_to?(:order)
          collection = order_by_order(collection, order_field, order_direction)
        elsif collection.respond_to?(:each)
          collection = order_by_sort(collection, order_field, order_direction)
        else
          ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.unorderable_collection'))
          Rails.logger.warn("Attempted to order something that wasn't a collection\n Object: #{collection}")
        end
      else
        ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.invalid_order_direction'))
      end

      return collection
    end

    # Order a collection using the order() method
    # Do nothing if the objects in the collection don't respond to the order_field
    #
    # === Parameters
    #
    # * +collection+ - A collection of objects that responds to order()
    # * +order_field+ - The field by which to order the collection
    # * +order_direction+ - An order direction (either :desc or :asc)
    def order_by_order(collection, order_field, order_direction)
      if collection.model.column_names.include?(order_field.to_s)
        collection = collection.order(order_field => order_direction)
      else
        ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.invalid_order_field'))
        Rails.logger.warn('Attempted to order a collection that contains object that does not respond to the order field.')
      end

      return collection
    end

    # Order a collection using the order() method
    # Do nothing if the objects in the collection don't respond to the order_field
    #
    # === Parameters
    #
    # * +collection+ - A collection of objects that responds to each
    # * +order_field+ - The field by which to order the collection
    # * +order_direction+ - An order direction (either :desc or :asc)
    def order_by_sort(collection, order_field, order_direction)
      begin
        collection.sort_by!(&order_field)
        if order_direction == :asc
          collection.reverse!
        end
      rescue NoMethodError => e
        ApiApe::ApeDebugger.instance.log_warning(I18n.t('api_ape.debug.warning.invalid_order_field'))
        Rails.logger.warn("Attempted to order a collection that contains object that do not respond to the order field. #{e.message}")
      end

      return collection
    end

  end
end