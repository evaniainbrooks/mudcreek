icons_json = Rails.root.join("config/bootstrap-icons.json")
BOOTSTRAP_ICON_NAMES = JSON.parse(icons_json.read).keys.freeze
