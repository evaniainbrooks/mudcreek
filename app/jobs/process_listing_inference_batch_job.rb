class ProcessListingInferenceBatchJob < ApplicationJob
  queue_as :default
  retry_on Errno::ECONNREFUSED, wait: 10.seconds, attempts: 3

  def perform(batch_id)
    batch = ListingInferenceBatch.unscoped.find(batch_id)
    Current.tenant = batch.tenant

    batch.update!(status: "processing")
    broadcast_progress(batch)

    images = collect_images(batch)
    batch.update!(total_count: images.size)
    broadcast_progress(batch)

    category_names = Listings::Category.pluck(:name)

    images.each do |filename, binary, content_type, original_blob|
      process_one_image(batch, filename, binary, content_type, original_blob, category_names)
    rescue => e
      Rails.logger.error("ListingInferenceBatch ##{batch.id} image error: #{e.message}")
      batch.increment!(:failed_count)
      broadcast_progress(batch)
    end

    batch.update!(status: "done")
    broadcast_progress(batch)
  rescue => e
    batch&.update!(status: "failed", error_message: e.message)
    broadcast_progress(batch) if batch
    raise
  end

  private

  def collect_images(batch)
    images = []
    batch.source_files.each do |attachment|
      blob = attachment.blob
      if zip?(blob)
        Listings::InferenceBatch::ZipExtractor.call(blob) do |name, data, content_type|
          images << [ name, data, content_type, nil ]
        end
      else
        data = blob.download
        images << [ blob.filename.to_s, data, blob.content_type, blob ]
      end
    end
    images
  end

  def zip?(blob)
    blob.content_type == "application/zip" ||
      blob.content_type == "application/x-zip-compressed" ||
      File.extname(blob.filename.to_s).downcase == ".zip"
  end

  def process_one_image(batch, filename, binary, content_type, original_blob, category_names)
    result = Listings::InferenceBatch::OllamaVisionService.call(binary, content_type, category_names)

    unless result.success
      Rails.logger.warn("Ollama failed for #{filename}: #{result.error}")
      batch.increment!(:failed_count)
      broadcast_progress(batch)
      return
    end

    listing = build_listing(result.data, batch)
    listing.save!

    if original_blob
      listing.images.attach(original_blob)
    else
      listing.images.attach(io: StringIO.new(binary), filename: filename, content_type: content_type)
    end

    batch.increment!(:processed_count)
    broadcast_progress(batch)
  end

  def build_listing(ai, batch)
    pricing_type = Listing.pricing_types.keys.include?(ai["pricing_type"]) ? ai["pricing_type"] : "firm"

    listing = Listing.new(
      name:         ai["name"].to_s.presence || "Untitled",
      description:  ai["description"].to_s.presence || "No description provided.",
      price_cents:  ai["price_cents"].to_i,
      pricing_type: pricing_type,
      listing_type: "sale",
      published:    false,
      lot_id:       batch.lot_id
    )

    matched_categories = Listings::Category.where(
      "LOWER(name) = ANY(?)",
      Array(ai["categories"]).map(&:downcase)
    )
    listing.categories = matched_categories

    Array(ai["properties"]).each do |prop|
      next if prop["name"].blank? || prop["value"].blank?
      listing.properties.build(name: prop["name"], value: prop["value"])
    end

    listing
  end

  def broadcast_progress(batch)
    Turbo::StreamsChannel.broadcast_replace_to(
      "listing_inference_batch_#{batch.id}",
      target:  "batch-progress",
      partial: "admin/listing_inference_batches/progress",
      locals:  { batch: batch.reload }
    )
  end
end
