module NativeEnum
  extend ActiveSupport::Concern

  class_methods do
    def native_enum(attribute, values, **options)
      enum(attribute, values.index_with { _1.to_s }, **options)
    end
  end
end
