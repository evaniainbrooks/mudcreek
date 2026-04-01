module Admin
  module TenantsHelper
    def admin_tenant_color_fields
      [
        { field: :primary_color,    label: "Primary Color",        description: "Buttons, badges, and highlights.",                        default: "#355E3B" },
        { field: :secondary_color,  label: "Secondary Color",      description: "Navbar background and secondary elements.",               default: "#6B3A2A" },
        { field: :tertiary_color,   label: "Accent Color",         description: "Highlights and accent elements.",                         default: "#C8A84B" },
        { field: :background_color, label: "Background Color",     description: "Page background (default: white).",                       default: "#ffffff" },
        { field: :text_color,       label: "Text Color",           description: "Body text color (default: near-black).",                  default: "#212529" },
        { field: :link_color,       label: "Link Color",           description: "Hyperlink text color.",                                   default: "#0d6efd" },
        { field: :footer_color,     label: "Footer Color",         description: "Footer background color.",                                default: "#f8f9fa" },
        { field: :container_color,  label: "Container Background", description: "Page container (rounded content wrapper) background.",    default: "#ffffff" },
        { field: :card_color,       label: "Card Background",      description: "Bootstrap card component background color.",              default: "#ffffff" }
      ]
    end
  end
end
