namespace :releases do
  desc "Create a GitHub release tagged with the current date/timestamp (e.g. 2026-04-12-143022)"
  task :create do
    tag = Time.now.strftime("%Y-%m-%d-%H%M%S")

    puts "Creating GitHub release #{tag}..."
    system("gh release create #{tag} --title #{tag} --generate-notes") ||
      abort("gh release create failed — ensure `gh` is installed and authenticated.")

    puts "Done. https://github.com/evaniainbrooks/mudcreek/releases/tag/#{tag}"
  end
end
