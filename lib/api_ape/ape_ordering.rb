module ApiApe
  class ApeOrdering

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
          #TODO: add warning about an invalid ordering
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
    # TODO: allow user to configure the sort attribute
    #
    # === Parameters
    #
    # * +collection+ - A collection of objects (should respond to each() or order())
    # * +order_direction+ - An order direction (either :desc or :asc)
    def order_collection(collection, order_direction)
      if order_direction.present?
        if collection.respond_to?(:order)
          begin
            collection = collection.order(created_at: order_direction)
          rescue NoMethodError => e
            #TODO: add warning about ordering an association that has no created_at date
          end
        elsif collection.respond_to?(:each)
          begin
            collection.sort_by!(&:created_at)
            if order_direction == :asc
              collection.reverse!
            end
          rescue NoMethodError => e
            #TODO: add warning about sorting an association that has no created_at date
          end
        else
          #TODO: add warning about ordering an association that cannot be ordered
        end
      end

      return collection
    end

  end
end