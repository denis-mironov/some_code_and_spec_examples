# Добавляет аргумент pagination к полям с connection_type, и передает его в context.

module Extensions
  class CustomConnectionExtension < GraphQL::Schema::Field::ConnectionExtension
    def apply
      field.argument(:pagination, Arguments::Pagination, required: false)
      super
    end

    def resolve(object:, arguments:, context:)
      args = arguments.dup
      context[:pagination] = args.delete(:pagination)
      super(object: object, arguments: args, context: context)
    end
  end
end
