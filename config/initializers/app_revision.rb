APP_REVISION = ENV["COMMIT_SHA"].presence ||
  `git rev-parse --short HEAD 2>/dev/null`.strip.presence ||
  "unknown"
