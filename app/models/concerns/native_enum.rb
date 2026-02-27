module NativeEnum
  extend ActiveSupport::Concern

  class_methods do
    # Declares a Rails enum backed by a PostgreSQL native enum type.
    # Each symbol/string value maps to its own string, so the database stores
    # the human-readable label rather than an integer.
    #
    #   native_enum :state, %i[on_sale sold cancelled]
    #
    # This gives you the usual Rails enum helpers:
    #   listing.on_sale?   listing.sold!
    #   Listing.on_sale    Listing.sold
    def native_enum(attribute, values, **options)
      enum(attribute, values.index_with { _1.to_s }, **options)
    end
  end
end
