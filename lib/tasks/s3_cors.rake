namespace :s3 do
  desc "Apply CORS policy to Active Storage S3 bucket (creates bucket if missing)"
  task set_cors: :environment do
    service = ActiveStorage::Blob.service
    s3_client = service.client.client
    bucket = service.bucket.name

    begin
      s3_client.head_bucket(bucket: bucket)
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
      s3_client.create_bucket(bucket: bucket)
      puts "Created: #{bucket}"
    end

    origins = Rails.env.production? ? [ ENV.fetch("APP_ORIGIN") ] : [ "http://localhost:3000", "http://*.lvh.me:3000" ]
    s3_client.put_bucket_cors(
      bucket: bucket,
      cors_configuration: {
        cors_rules: [ {
          allowed_headers: [ "*" ],
          allowed_methods: [ "GET", "PUT", "POST" ],
          allowed_origins: origins,
          expose_headers: [ "ETag", "Origin", "Content-Type" ],
          max_age_seconds: 3600
        } ]
      }
    )
    puts "CORS applied"

    if Rails.env.development?
      s3_client.put_bucket_policy(
        bucket: bucket,
        policy: {
          "Version" => "2012-10-17",
          "Statement" => [ {
            "Effect" => "Allow",
            "Principal" => "*",
            "Action" => "s3:GetObject",
            "Resource" => "arn:aws:s3:::#{bucket}/*"
          } ]
        }.to_json
      )
      puts "Public-read bucket policy applied"
    end
  end
end
