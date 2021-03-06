module ActiveRecord
  class PredicateBuilder

    def initialize(engine)
      @engine = engine
    end

    def build_from_hash(attributes, default_table)
      predicates = attributes.map do |column, value|
        table = default_table

        if value.is_a?(Hash)
          table = Arel::Table.new(column, :engine => @engine)
          build_from_hash(value, table)
        else
          column = column.to_s

          if column.include?('.')
            table_name, column = column.split('.', 2)
            table = Arel::Table.new(table_name, :engine => @engine)
          end

          attribute = table[column] || Arel::Attribute.new(table, column.to_sym)

          case value
          when Array, ActiveRecord::Associations::AssociationCollection, ActiveRecord::NamedScope::Scope
            attribute.in(value)
          when Range
            # TODO : Arel should handle ranges with excluded end.
            if value.exclude_end?
              [attribute.gteq(value.begin), attribute.lt(value.end)]
            else
              attribute.in(value)
            end
          else
            attribute.eq(value)
          end
        end
      end

      predicates.flatten
    end

  end
end
