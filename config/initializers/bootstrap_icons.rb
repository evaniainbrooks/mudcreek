BOOTSTRAP_ICON_NAMES = JSON.parse(
  File.read(Rails.root.join("node_modules/bootstrap-icons/font/bootstrap-icons.json"))
).keys.freeze
