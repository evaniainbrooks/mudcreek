require "aws-sdk-s3"

namespace :localstack do
  desc "Create S3 bucket in LocalStack"
  task create_bucket: :environment do
    service = ActiveStorage::Blob.service
    client = service.client
    bucket = service.bucket.name
    client.create_bucket(bucket: bucket)
    puts "Created: #{bucket}"
  rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
    puts "Already exists: #{bucket}"
  end
end
