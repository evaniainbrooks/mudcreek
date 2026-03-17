module Listings
  module InferenceBatch
    class ZipExtractor
      IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .webp .gif .bmp].freeze

      def self.call(blob, &block)
        new(blob).call(&block)
      end

      def initialize(blob)
        @blob = blob
      end

      def call
        @blob.open do |tmp|
          Zip::File.open(tmp.path) do |zip|
            zip.each do |entry|
              next unless entry.file?
              ext = File.extname(entry.name).downcase
              next unless IMAGE_EXTENSIONS.include?(ext)

              data = entry.get_input_stream.read
              content_type = Marcel::MimeType.for(data, name: entry.name)
              yield entry.name, data, content_type
            end
          end
        end
      end
    end
  end
end
