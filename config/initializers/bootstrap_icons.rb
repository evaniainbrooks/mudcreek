icons_json = Rails.root.join("node_modules/bootstrap-icons/font/bootstrap-icons.json")
BOOTSTRAP_ICON_NAMES = icons_json.exist? ? JSON.parse(icons_json.read).keys.freeze : [].freeze
