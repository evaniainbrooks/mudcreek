default_password = Rails.application.credentials&.seeds&.default_user_password || "default"

# Tenants
mudcreek = Tenant.find_or_create_by!(key: "mudcreek") do |t|
  t.name = "Mudcreek"
  t.tagline = "Auctions & Consignment"
  t.default = true
end

Tenant.find_or_create_by!(key: "whitelabel") do |t|
  t.name = "Whitelabel"
  t.default = false
end

mudcreek.create_address!(
  address_type:   "primary",
  street_address: "101 River Road",
  city:           "Kamloops",
  province:       "BC",
  postal_code:    "V2C 2A1",
  country:        "CA",
  latitude:       50.6745,
  longitude:      -120.3273
) unless mudcreek.address

[
  { platform: :facebook,  slug: "mudcreekauctions" },
  { platform: :instagram, slug: "mudcreekauctions" },
  { platform: :youtube,   slug: "@mudcreekauctions" }
].each do |attrs|
  mudcreek.social_media_accounts.find_or_create_by!(platform: attrs[:platform]) do |a|
    a.slug = attrs[:slug]
  end
end

unless mudcreek.logo.attached?
  mudcreek.logo.attach(
    io: Rails.root.join("spec/fixtures/images/mudcreek_logo.png").open("rb"),
    filename: "mudcreek_logo.png",
    content_type: "image/png"
  )
end

unless mudcreek.auction_placeholder.attached?
  mudcreek.auction_placeholder.attach(
    io: Rails.root.join("spec/fixtures/images/barn.jpg").open("rb"),
    filename: "barn.jpg",
    content_type: "image/jpeg"
  )
end

puts "Seeded #{Tenant.count} tenants."

# Backfill any existing records that predate the tenant column
[ Role, Permission, User, Listing, Listings::Category, CartItem ].each do |klass|
  count = klass.where(tenant_id: nil).update_all(tenant_id: mudcreek.id)
  puts "Backfilled #{count} #{klass.name} records to mudcreek tenant." if count > 0
end

# Roles & Permissions
super_admin = Role.find_or_create_by!(name: "super_admin") do |r|
  r.tenant = mudcreek
  r.description = "Full access to everything."
end

admin = Role.find_or_create_by!(name: "admin") do |r|
  r.tenant = mudcreek
  r.description = "Full access to listings. No access to users or roles."
end

Role.find_or_create_by!(name: "user") do |r|
  r.tenant = mudcreek
  r.description = "Standard user with no admin permissions."
end

Permission::RESOURCES.each do |resource|
  Permission::ACTIONS.each do |action|
    super_admin.permissions.find_or_create_by!(resource: resource, action: action) do |p|
      p.tenant = mudcreek
    end
  end
end

admin_resources = %w[Listing Auction Lot Listings::Category Offer DiscountCode DeliveryMethod Listings::RentalRatePlan AuctionListing AuctionRegistration]
admin_resources.each do |resource|
  Permission::ACTIONS.each do |action|
    admin.permissions.find_or_create_by!(resource: resource, action: action) do |p|
      p.tenant = mudcreek
    end
  end
end

# Invoice-specific permissions for admin
%w[index show].each do |action|
  admin.permissions.find_or_create_by!(resource: "Invoice", action: action) do |p|
    p.tenant = mudcreek
  end
end

puts "Seeded #{Role.count} roles and #{Permission.count} permissions."

Offer.destroy_all
CartItem.destroy_all
Lot.destroy_all
User.destroy_all

User.create!(
  tenant: mudcreek,
  email_address: "admin@mudcreek.com",
  first_name: "Default",
  last_name: "Admin",
  password: default_password,
  password_confirmation: default_password,
  activated_at: 1.day.ago,
  role: super_admin
)

# Generate fake users for dev pagination testing
if Rails.env.local?
  require "faker"
  15.times do
    password = Faker::Internet.password
    User.create!(
      tenant: mudcreek,
      email_address: Faker::Internet.unique.email,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      password: password,
      password_confirmation: password
    )
  end
end

puts "Seeded #{User.count} users."

user_ids = User.where(tenant: mudcreek).pluck(:id)

# Lots
admin_user = User.find_by!(email_address: "admin@mudcreek.com")

lot_data = [
  { name: "Henderson Estate",     number: "001", show_attribution: true  },
  { name: "Blackwood Collection", number: "002", show_attribution: true  },
  { name: "Greenfield Manor",     number: "003", show_attribution: false },
  { name: "Chapman Farm",         number: "004", show_attribution: true  },
  { name: "Personal Items",       number: "005", show_attribution: false }
]

lots = lot_data.each_with_object({}) do |attrs, hash|
  lot = Lot.find_or_create_by!(name: attrs[:name]) do |l|
    l.tenant = mudcreek
    l.number = attrs[:number]
    l.owner  = admin_user
  end
  lot.update!(show_attribution: attrs[:show_attribution])
  hash[attrs[:name]] = lot
end

puts "Seeded #{Lot.count} lots."

listing_data = [
  # Furniture
  { name: "Victorian Parlour Chair",       price: 185,  pricing_type: :negotiable, description: "Beautifully carved walnut parlour chair with original needlepoint upholstery in a floral medallion pattern. Sturdy legs, minimal wear — a genuine Victorian-era piece from the Henderson drawing room.", published: true },
  { name: "Oak Dining Table with Six Chairs", price: 450, description: "Solid quarter-sawn oak dining suite with a pedestal base and six matching ladder-back chairs with rush seats. Extends to seat ten. Light surface scratches only.", published: true },
  { name: "Mahogany Dresser with Mirror",  price: 320,  pricing_type: :negotiable, description: "Seven-drawer mahogany dresser with a bevelled swivel mirror and original brass hardware. Dovetail joinery throughout. Excellent original finish with minor patina.", published: true },
  { name: "Brass Bed Frame",              price: 275,  description: "Full-size ornate brass bed frame with original side rails. Thick tubing, solid castings, and fully functional. Includes slats. Circa 1910.", published: true },
  { name: "Antique Writing Desk",         price: 385,  pricing_type: :negotiable, description: "Drop-front secretary desk in cherry with fitted interior — pigeon holes, small drawers, and a pull-out writing surface. Three lower drawers with original locks and skeleton keys.", published: true },
  { name: "Windsor Chairs Set of Four",   price: 220,  pricing_type: :negotiable, description: "Matched set of four bow-back Windsor chairs in original black paint with gold pinstriping. Solid and sturdy with minor paint loss. Farm-fresh from the Chapman dining room.", published: true },
  { name: "Cedar Chest",                  price: 165,  pricing_type: :negotiable, description: "Aromatic red cedar hope chest with tray insert and original hardware. Interior cedar is fragrant and unlined. Some light exterior scratches. Ideal for linens or blankets.", published: true },
  { name: "Chesterfield Sofa",            price: 495,  pricing_type: :negotiable, description: "Classic rolled-arm Chesterfield in original burgundy leather with deep button tufting. Some patina on the armrests consistent with age. Extremely comfortable and structurally sound.", published: true },
  { name: "Teak Garden Bench",            price: 140,  description: "Three-seat teak garden bench with slatted back and armrests. Silvered to a handsome grey with age. Hardware intact, no rot. Great outdoor piece.", published: true },
  { name: "Rocking Chair",                price: 95,   pricing_type: :negotiable, description: "Pressed-back oak rocking chair with a carved floral crest rail and turned spindles. Original finish in good condition. Rockers show normal wear. Comfortable and solid.", published: true },

  # Antiques & Collectibles
  { name: "Wedgwood Tea Service",         price: 145,  description: "Twenty-two piece Wedgwood Cornucopia tea service including teapot, creamer, sugar, six cups and saucers, and serving plates. Minor gilt wear, no chips or cracks.", published: true },
  { name: "Bakelite Table Radio",         price: 85,   pricing_type: :negotiable, description: "1940s brown Bakelite cathedral radio in excellent cosmetic condition. Receives AM. Warm tone and impressive volume. A striking piece of mid-century design.", published: true },
  { name: "Clockwork Mantle Clock",       price: 195,  description: "Eight-day French mantle clock in a black slate and marble case with gilt bronze mounts. Strikes on the half and hour. Running and keeping good time. Key included.", published: true },
  { name: "Depression Glass Bowl Set",    price: 75,   description: "Eleven-piece set of pink Depression glass in the Sharon rose pattern — six salad plates, four berry bowls, and a large serving bowl. No chips or cracks.", published: true },
  { name: "Sterling Silver Cutlery Set",  price: 340,  pricing_type: :negotiable, description: "Sixty-piece Birks sterling silver flatware service for twelve in the Chantilly pattern. Stored in original fitted case. Some tarnish, polishes beautifully. Weighs over 2 kg.", published: true },
  { name: "Vintage Tin Advertising Signs", price: 55,  pricing_type: :negotiable, description: "Lot of four original lithograph tin signs — two tobacco, one feed store, one soft drink — ranging from 12\" to 18\" wide. Surface rust and honest patina on all.", published: true },
  { name: "Pewter Tankard Set",           price: 90,   description: "Set of six English pewter tankards with hinged lids, hallmarked and dated circa 1890. No dents or damage. Rich grey patina. Displayed on original wooden rack.", published: true },
  { name: "Brass Ship's Compass",         price: 125,  description: "Gimbal-mounted brass binnacle compass in original mahogany box with a swing ring. Card is clear and needle responsive. A handsome nautical antique.", published: true },
  { name: "Hand-painted China Plates",    price: 95,   description: "Set of eight hand-painted Austrian china dinner plates with detailed fruit and floral borders on cream grounds. All signed by the artist. No damage.", published: true },
  { name: "Cast Iron Doorstop Collection", price: 45,  description: "Four original painted cast iron doorstops — a Scottie dog, a lighthouse, a rooster, and a basket of flowers. Original paint intact on all. Charming farmhouse pieces.", published: true },

  # Jewelry & Watches
  { name: "Gold Locket Necklace",         price: 180,  description: "Yellow gold oval locket on a fine chain, circa 1890–1910. Interior holds two original photos. Tests at 10K. Minor surface wear. 3.4 g total weight.", published: true },
  { name: "Gentleman's Pocket Watch",     price: 285,  pricing_type: :negotiable, description: "Illinois Bunn Special 21-jewel railroad-grade pocket watch in a yellow gold-filled screw-back case. Running accurately. Dial has a hairline near six — noted in price.", published: true },
  { name: "Pearl Bracelet",               price: 95,   description: "Three-strand cultured pearl bracelet with a gold-filled clasp set with a small garnet. Pearls are uniform in size and lustre. Clasp functional.", published: true },
  { name: "Cameo Brooch",                 price: 75,   description: "Shell cameo brooch depicting a classical profile in a rolled gold frame with pin catch intact. No chips. Circa 1880. Fine detail on the carving.", published: true },
  { name: "Silver Cufflinks",             price: 65,   description: "Pair of sterling silver engine-turned cufflinks in original fitted leather box. Hallmarked Birmingham, 1927. Toggle backs in good working order.", published: true },
  { name: "Amethyst Ring",                price: 145,  pricing_type: :negotiable, description: "Victorian silver amethyst and seed pearl cluster ring. Oval cushion-cut amethyst, deep purple, approximately 3 ct. Shank tests silver. Ring size 6.5.", published: true },

  # Tools & Workshop
  { name: "Stanley Hand Plane Set",       price: 85,   pricing_type: :negotiable, description: "Collection of five Stanley bench planes: #3, #4, #5, #6, and #7. All original with tight mouths and functional totes. Some surface rust — irons are sound.", published: true },
  { name: "Woodworking Chisel Set",       price: 55,   description: "Set of eight socket chisels in a canvas roll — graduated from ¼\" to 1½\". Handles are sound, blades hold an edge well. Stamped 'P.S.&W.' manufacturer.", published: true },
  { name: "Cast Iron Bench Vise",         price: 95,   description: "Heavy 5\" jaw cast iron bench vise with swivel base and pipe jaws. Smooth action, no cracks or stripped threads. Mounts securely to a workbench.", published: true },
  { name: "Crosscut Hand Saw",            price: 40,   description: "Disston No. 12 crosscut hand saw with a turned apple handle and 26\" blade. Teeth have been sharpened and set. Cuts cleanly. Medallion intact.", published: true },
  { name: "Vintage Level Set",            price: 35,   description: "Three vintage wood and brass spirit levels — 12\", 24\", and 36\" — all with readable bubbles. Some finish wear. Great for display or use.", published: true },

  # Books & Media
  { name: "Encyclopedia Britannica Set",  price: 95,   description: "Complete 1965 Encyclopedia Britannica in 24 volumes plus index. Burgundy cloth with gilt titles. All spines tight, pages clean. Includes original wooden bookends.", published: true },
  { name: "Vinyl Record Collection",      price: 85,   pricing_type: :negotiable, description: "Box of approximately 80 LP records — jazz, classical, and easy listening. Mostly 1950s–70s pressings. Several in original sleeves. Spot-checked: all play without skipping.", published: true },
  { name: "First Edition Poetry Collection", price: 125, description: "Twelve early twentieth-century poetry volumes including a signed Robert Service first edition and a fine Kipling Barrack-Room Ballads. All in original boards.", published: true },

  # Kitchenware & Dining
  { name: "Copper Cookware Set",          price: 185,  description: "Seven-piece set of French copper pots and pans — two saucepans, a sauté pan, a rondeau, a stockpot, and two lids — all tin-lined. Matching dovetailed seams.", published: true },
  { name: "Vintage Pyrex Mixing Bowl Set", price: 65,  description: "Set of four nested Pyrex mixing bowls in the Primary Colors pattern: red, blue, green, and yellow. No chips or cracks. Excellent colour.", published: true },
  { name: "Crystal Decanter Set",         price: 110,  description: "Cut crystal decanter with eight matching rocks glasses in a Greek key pattern. All pieces present and undamaged. Stored in original felt-lined box.", published: true },
  { name: "Silverplate Serving Tray",     price: 75,   description: "Large oval silverplate gallery tray with pierced border and two handles. Maker's mark on base. Silver is thick, minimal wear to high points. 22\" long.", published: true },
  { name: "Cast Iron Dutch Oven",         price: 55,   description: "No. 10 Griswold cast iron Dutch oven with lid. Large block logo, Erie PA. Seasoned black, no cracks or pits. A prized piece for any cast iron collector.", published: true },

  # Art & Decor
  { name: "Watercolour Landscape Painting", price: 225, pricing_type: :negotiable, description: "Framed original watercolour of a misty river valley, signed lower right 'E. Sutton 1938.' 18\" × 24\" sheet in original gilt frame. Light mat foxing only.", published: true },
  { name: "Hand-hooked Wool Rug",         price: 195,  description: "Circa 1920 hand-hooked wool rug, 4' × 6', depicting a folk art floral wreath on a navy ground. Wool is dense and colours are vibrant. Bound edges intact.", published: true },
  { name: "Framed Botanical Prints Set",  price: 85,   description: "Set of six antique hand-coloured botanical lithographs in matching mahogany frames. Circa 1870. Consistent minor foxing typical for age. Attractive grouping.", published: true },
  { name: "Bronze Horse Figurine",        price: 165,  description: "Solid bronze sculpture of a trotting horse on a marble plinth, signed 'Dubois' on the base. 8\" tall. Rich dark patina. No damage.", published: true },
  { name: "Tiffany-style Table Lamp",     price: 285,  pricing_type: :negotiable, description: "Leaded glass dragonfly shade on a cast metal base. 20\" shade diameter, overall height 26\". Wired and tested — all panels intact with no repairs.", published: true },
  { name: "Oil Portrait",                 price: 195,  pricing_type: :negotiable, description: "19th-century oil on canvas portrait of a seated gentleman in a dark coat. 24\" × 30\" canvas in carved gilt frame. Some inpainting visible under raking light.", published: true },

  # Vintage Clothing & Accessories
  { name: "Mink Stole",                   price: 145,  pricing_type: :negotiable, description: "Full natural mink stole with satin lining in ivory. Pelts are supple and well-matched. Minimal shedding. Hook-and-eye closure. Stored properly in cedar.", published: true },
  { name: "Men's Tweed Hunting Jacket",   price: 85,   description: "Original Harris Tweed Norfolk jacket in olive herringbone, size 42 long. Four patch pockets, belted back, and gun patch on right shoulder. Light wear only.", published: true },
  { name: "Beaded Evening Bag",           price: 55,   description: "Edwardian micro-beaded evening bag in a peacock and floral motif with a silver-tone frame and chain handle. Clasp functional. Lining intact.", published: true },
  { name: "Vintage Hat Collection",       price: 65,   description: "Collection of six vintage women's hats from the 1940s–60s — felts, a straw, and a cocktail fascinator — in original hatbox. All in wearable condition.", published: true },

  # Electronics
  { name: "Grundig Shortwave Radio",      price: 95,   pricing_type: :negotiable, description: "Grundig Satellit 500 shortwave receiver in original case with manual. Receives AM, FM, and shortwave bands. Tested and functional. Display is bright.", published: true },
  { name: "Vintage Rotary Telephone",     price: 45,   description: "Western Electric Model 500 rotary dial telephone in original harvest gold. Dial is smooth and springy. Handset cord intact. Purely decorative.", published: true },
  { name: "8mm Film Projector",           price: 75,   pricing_type: :negotiable, description: "Eumig P8 Phonomatic 8mm film projector with built-in speaker and reverse function. Lamp works, motor runs smoothly. Two reels of family film included.", published: true },

  # Garden & Outdoor
  { name: "Cast Iron Garden Urns",        price: 165,  description: "Pair of matching cast iron garden urns on pedestal bases. Classical acanthus leaf design. Light surface rust — structurally sound. 18\" tall each.", published: true },
  { name: "Antique Wheelbarrow",          price: 85,   pricing_type: :negotiable, description: "Vintage wooden wheelbarrow with iron wheel and banded hardwood tray. Painted red, well-worn. Functional and charming as a garden planter.", published: true },
  { name: "Copper Garden Lanterns",       price: 95,   description: "Set of three wall-mount copper lanterns in graduated sizes. Aged verdigris patina. Glass panels intact. Wired for standard bulbs.", published: true },

  # Furniture (non-auction)
  { name: "Oak Roll-top Desk",            price: 545,  pricing_type: :negotiable, description: "Large S-roll oak cylinder desk with fitted interior — twelve pigeon holes, four small drawers, and a centre prospect door. Four full drawers below. Original lock and key. Circa 1905. Finish is original and even.", published: true },
  { name: "Mahogany Sideboard",           price: 395,  pricing_type: :negotiable, description: "Edwardian mahogany sideboard with two centre drawers flanked by a pair of carved panel doors. Satinwood inlay on the frieze. Original brass ring pulls throughout. Excellent original finish.", published: true },
  { name: "Victorian Hall Tree",          price: 225,  description: "Cast iron and oak hall tree with six double coat hooks, an umbrella stand, and a lower storage bench with lift lid. Original japanned finish with gilt highlights. Some paint chips.", published: true },
  { name: "Walnut Bookcase with Glass Doors", price: 310, pricing_type: :negotiable, description: "Three-section stacking barrister bookcase in walnut with lift-front glass doors. Four shelves total. Original casters intact. Ideal for a library or study.", published: true },

  # Antiques & Collectibles (non-auction)
  { name: "Swiss Cylinder Music Box",     price: 285,  pricing_type: :negotiable, description: "Late Victorian Swiss cylinder music box in a rosewood case with inlaid lid. Plays six airs on a 15 cm cylinder. Runs smoothly and plays cleanly. Original crank and tune card.", published: true },
  { name: "Dome-top Steamer Trunk",       price: 115,  description: "Canvas and wood dome-top steamer trunk with original tray insert, brass hardware, and interior paper lining. Lock intact, key included. Sits flat. Great storage piece.", published: true },
  { name: "Brass Aneroid Barometer",      price: 145,  pricing_type: :negotiable, description: "Eight-inch brass aneroid barometer in an oak case with bevelled glass. Reads accurately — recently calibrated. Maker's name on the dial. Wall-mount bracket included.", published: true },
  { name: "Pressed Glass Compote Set",    price: 60,   description: "Four-piece pressed glass compote and nappy set in the Hobstar pattern. Deep relief, excellent clarity, no chips. Likely American, circa 1900–1910.", published: true },

  # Jewelry & Watches (non-auction)
  { name: "Garnet Cluster Brooch",        price: 110,  description: "Victorian yellow gold garnet and seed pearl cluster brooch in a floral spray design. Ten round garnets, deep red. Pin catch intact. Tests 10K. 4.8 g.", published: true },
  { name: "Gold Watch Chain",             price: 155,  pricing_type: :negotiable, description: "Heavy 14K yellow gold Albert watch chain with T-bar and swivel clip. 36 cm overall length. Hallmarked throughout. 18.2 g. No repairs.", published: true },

  # Tools & Workshop (non-auction)
  { name: "Brace and Bit Set",            price: 65,   description: "North Brothers Yankee brace with a set of twelve graduated auger bits in a canvas roll. Ratchet mechanism smooth in both directions. Bits range from ¼\" to 1\". All sharp.", published: true },
  { name: "Drawknife",                    price: 35,   description: "Witherby 10\" drawknife with turned hardwood handles. Blade holds a fine edge with no pitting. Light surface rust only. A pleasure to use.", published: true },

  # Books & Media (non-auction)
  { name: "National Geographic Collection", price: 75, pricing_type: :negotiable, description: "Complete run of National Geographic from January 1960 through December 1979 — 240 issues — in original yellow-spine binders. All present and in excellent condition.", published: true },
  { name: "Vintage Road Atlas Collection", price: 40,  description: "Twelve Esso and Gulf road atlases of Canada and the United States, 1948 to 1971. Clean maps, no writing. A wonderful record of mid-century roads and place names.", published: true },

  # Kitchenware & Dining (non-auction)
  { name: "Stoneware Butter Churn",       price: 85,   description: "Four-gallon salt-glazed stoneware butter churn with cobalt floral decoration. Wooden lid and original dash intact. No cracks. Signed by the potter on the base.", published: true },
  { name: "Griswold Skillet Collection",  price: 135,  pricing_type: :negotiable, description: "Set of five Griswold cast iron skillets: No. 3, 5, 7, 8, and 10. All large block logos, Erie PA. Seasoned and ready to use. No cracks or pits.", published: true },

  # Art & Decor (non-auction)
  { name: "Carved Wooden Duck Decoy",     price: 145,  pricing_type: :negotiable, description: "Hand-carved and painted mallard drake decoy, circa 1940. Glass eyes, original paint in very good condition with honest gunning wear. Signed on the base. A fine decorative piece.", published: true },
  { name: "Needlework Sampler",           price: 95,   description: "Framed 19th-century wool-on-linen sampler worked by 'Mary E. Alcott, aged 12, 1864.' Alphabet, numerals, and a verse above a house and garden scene. Original gilt frame.", published: true },
  { name: "Reverse Painting on Glass",    price: 175,  pricing_type: :negotiable, description: "Framed Chinese export reverse painting on glass depicting a harbour scene with sampans and pagodas. 14\" × 20\" image in a lacquered frame. Colours are vivid, no flaking.", published: true },

  # Vintage Clothing & Accessories (non-auction)
  { name: "Lady's Victorian Brooch Set",  price: 85,   description: "Three Victorian gold-fill brooches — a crescent set with seed pearls, a bar pin with a turquoise cabochon, and a target brooch with red and white paste stones. All catches functional.", published: true },
  { name: "Edwardian Lace Collar",        price: 45,   description: "Handmade Brussels needle lace collar, circa 1900–1910. Intricate floral and scroll pattern. Pristine condition — never worn. Mounted on archival card.", published: true },

  # Electronics (non-auction)
  { name: "Underwood Typewriter",         price: 125,  pricing_type: :negotiable, description: "Underwood No. 5 standard typewriter in original case. All keys strike cleanly, carriage returns and advances smoothly. Ribbon is dry but the machine is complete and functional.", published: true },
  { name: "Kodak Carousel Projector",     price: 55,   description: "Kodak Carousel 750H slide projector with a 102 mm f/2.8 lens and remote control. Lamp is bright, tray advance quiet and reliable. Includes two 80-slide trays.", published: true },

  # Garden & Outdoor (non-auction)
  { name: "Stone Garden Birdbath",        price: 110,  description: "Cast stone pedestal birdbath with a fluted column and scalloped basin. Weathered grey with lichen. Basin holds water. 26\" overall height. No chips or cracks.", published: true },
  { name: "Wrought Iron Plant Stand",     price: 75,   pricing_type: :negotiable, description: "Five-tier wrought iron plant stand with scrollwork legs and graduated shelves. Holds up to fifteen pots. Original black paint with light rust. Indoor or covered porch use.", published: true }
]

listing_data.each do |attrs|
  Listing.find_or_create_by!(name: attrs[:name]) do |l|
    l.tenant       = mudcreek
    l.price        = attrs[:price]
    l.pricing_type = attrs[:pricing_type] || :firm
    l.description  = attrs[:description]
    l.published    = attrs[:published]
    l.owner_id     = user_ids.sample
    l.state        = [ :sold, :on_sale ].sample
  end
end

puts "Seeded #{Listing.count} listings."

# Listing Properties
listing_properties = {
  # Furniture
  "Victorian Parlour Chair" => [
    { name: "Material",   value: "Carved walnut" },
    { name: "Style",      value: "Victorian" },
    { name: "Upholstery", value: "Original needlepoint" },
    { name: "Condition",  value: "Good — minimal wear" }
  ],
  "Oak Dining Table with Six Chairs" => [
    { name: "Material",   value: "Quarter-sawn oak" },
    { name: "Seats",      value: "6 (extends to 10)" },
    { name: "Base",       value: "Pedestal" },
    { name: "Condition",  value: "Good — light surface scratches" }
  ],
  "Mahogany Dresser with Mirror" => [
    { name: "Material",   value: "Mahogany" },
    { name: "Drawers",    value: "7" },
    { name: "Hardware",   value: "Original brass" },
    { name: "Mirror",     value: "Bevelled swivel" }
  ],
  "Brass Bed Frame" => [
    { name: "Material",   value: "Brass" },
    { name: "Size",       value: "Full" },
    { name: "Circa",      value: "1910" },
    { name: "Includes",   value: "Side rails and slats" }
  ],
  "Antique Writing Desk" => [
    { name: "Material",   value: "Cherry" },
    { name: "Style",      value: "Drop-front secretary" },
    { name: "Interior",   value: "Pigeon holes, small drawers" },
    { name: "Keys",       value: "Skeleton keys included" }
  ],
  "Chesterfield Sofa" => [
    { name: "Material",   value: "Leather" },
    { name: "Colour",     value: "Burgundy" },
    { name: "Style",      value: "Rolled-arm, button tufted" },
    { name: "Condition",  value: "Good — armrest patina" }
  ],
  "Rocking Chair" => [
    { name: "Material",   value: "Oak" },
    { name: "Style",      value: "Pressed-back" },
    { name: "Condition",  value: "Good — normal rocker wear" }
  ],

  # Antiques & Collectibles
  "Wedgwood Tea Service" => [
    { name: "Maker",      value: "Wedgwood" },
    { name: "Pattern",    value: "Cornucopia" },
    { name: "Pieces",     value: "22" },
    { name: "Condition",  value: "Excellent — no chips or cracks" }
  ],
  "Clockwork Mantle Clock" => [
    { name: "Movement",   value: "8-day French" },
    { name: "Strike",     value: "Half and hour" },
    { name: "Case",       value: "Black slate and marble" },
    { name: "Key",        value: "Included" }
  ],
  "Sterling Silver Cutlery Set" => [
    { name: "Material",   value: "Sterling silver" },
    { name: "Maker",      value: "Birks" },
    { name: "Pattern",    value: "Chantilly" },
    { name: "Pieces",     value: "60 (service for 12)" },
    { name: "Weight",     value: "Over 2 kg" }
  ],
  "Pewter Tankard Set" => [
    { name: "Material",   value: "English pewter" },
    { name: "Quantity",   value: "6" },
    { name: "Circa",      value: "1890" },
    { name: "Includes",   value: "Original wooden rack" }
  ],
  "Crystal Decanter Set" => [
    { name: "Pattern",    value: "Greek key" },
    { name: "Pieces",     value: "9 (decanter + 8 glasses)" },
    { name: "Condition",  value: "Excellent — no damage" },
    { name: "Storage",    value: "Original felt-lined box" }
  ],
  "Cast Iron Dutch Oven" => [
    { name: "Maker",      value: "Griswold" },
    { name: "Logo",       value: "Large block, Erie PA" },
    { name: "Size",       value: "No. 10" },
    { name: "Condition",  value: "Seasoned black — no cracks" }
  ],

  # Jewelry & Watches
  "Gold Locket Necklace" => [
    { name: "Metal",      value: "Yellow gold (10K)" },
    { name: "Era",        value: "Circa 1890–1910" },
    { name: "Weight",     value: "3.4 g" },
    { name: "Condition",  value: "Good — minor surface wear" }
  ],
  "Gentleman's Pocket Watch" => [
    { name: "Maker",      value: "Illinois Watch Co." },
    { name: "Grade",      value: "Bunn Special" },
    { name: "Jewels",     value: "21" },
    { name: "Case",       value: "Yellow gold-filled, screw-back" },
    { name: "Dial",       value: "Hairline near six o'clock" }
  ],
  "Amethyst Ring" => [
    { name: "Metal",      value: "Silver" },
    { name: "Stone",      value: "Oval cushion-cut amethyst, ~3 ct" },
    { name: "Accents",    value: "Seed pearls" },
    { name: "Ring Size",  value: "6.5" },
    { name: "Style",      value: "Victorian cluster" }
  ],
  "Silver Cufflinks" => [
    { name: "Metal",      value: "Sterling silver" },
    { name: "Style",      value: "Engine-turned" },
    { name: "Hallmark",   value: "Birmingham, 1927" },
    { name: "Backs",      value: "Toggle" }
  ],

  # Tools & Workshop
  "Stanley Hand Plane Set" => [
    { name: "Maker",      value: "Stanley" },
    { name: "Planes",     value: "#3, #4, #5, #6, #7" },
    { name: "Quantity",   value: "5" },
    { name: "Condition",  value: "Some surface rust — irons sound" }
  ],
  "Cast Iron Bench Vise" => [
    { name: "Jaw Width",  value: "5\"" },
    { name: "Base",       value: "Swivel" },
    { name: "Pipe Jaws",  value: "Yes" },
    { name: "Condition",  value: "Good — smooth action, no cracks" }
  ],
  "Crosscut Hand Saw" => [
    { name: "Maker",      value: "Disston" },
    { name: "Model",      value: "No. 12" },
    { name: "Blade",      value: "26\"" },
    { name: "Condition",  value: "Sharpened and set" }
  ],

  # Books & Media
  "Encyclopedia Britannica Set" => [
    { name: "Edition",    value: "1965" },
    { name: "Volumes",    value: "24 + index" },
    { name: "Binding",    value: "Burgundy cloth, gilt titles" },
    { name: "Includes",   value: "Original wooden bookends" }
  ],
  "Vinyl Record Collection" => [
    { name: "Quantity",   value: "Approx. 80 LPs" },
    { name: "Genres",     value: "Jazz, classical, easy listening" },
    { name: "Era",        value: "1950s–70s" },
    { name: "Condition",  value: "Spot-checked — all play" }
  ],

  # Art & Decor
  "Watercolour Landscape Painting" => [
    { name: "Artist",     value: "E. Sutton" },
    { name: "Year",       value: "1938" },
    { name: "Medium",     value: "Watercolour" },
    { name: "Size",       value: "18\" × 24\"" },
    { name: "Frame",      value: "Original gilt" }
  ],
  "Tiffany-style Table Lamp" => [
    { name: "Shade",      value: "Leaded glass, dragonfly motif" },
    { name: "Shade Diameter", value: "20\"" },
    { name: "Height",     value: "26\"" },
    { name: "Condition",  value: "All panels intact, wired and tested" }
  ],
  "Bronze Horse Figurine" => [
    { name: "Material",   value: "Solid bronze" },
    { name: "Height",     value: "8\"" },
    { name: "Base",       value: "Marble plinth" },
    { name: "Signed",     value: "Dubois" }
  ],

  # Clothing & Accessories
  "Men's Tweed Hunting Jacket" => [
    { name: "Material",   value: "Harris Tweed" },
    { name: "Colour",     value: "Olive herringbone" },
    { name: "Size",       value: "42 Long" },
    { name: "Style",      value: "Norfolk jacket" }
  ],
  "Mink Stole" => [
    { name: "Material",   value: "Natural mink" },
    { name: "Lining",     value: "Ivory satin" },
    { name: "Closure",    value: "Hook-and-eye" },
    { name: "Condition",  value: "Good — minimal shedding" }
  ],

  # Electronics
  "Grundig Shortwave Radio" => [
    { name: "Model",      value: "Satellit 500" },
    { name: "Bands",      value: "AM, FM, shortwave" },
    { name: "Condition",  value: "Tested and functional" },
    { name: "Includes",   value: "Original case and manual" }
  ],
  "Vintage Rotary Telephone" => [
    { name: "Maker",      value: "Western Electric" },
    { name: "Model",      value: "500" },
    { name: "Colour",     value: "Harvest gold" },
    { name: "Use",        value: "Decorative" }
  ],
  "8mm Film Projector" => [
    { name: "Maker",      value: "Eumig" },
    { name: "Model",      value: "P8 Phonomatic" },
    { name: "Format",     value: "8mm" },
    { name: "Includes",   value: "Two reels of family film" }
  ]
}

listing_properties.each do |listing_name, properties|
  next if properties.empty?
  listing = Listing.find_by(name: listing_name)
  next unless listing

  properties.each_with_index do |attrs, idx|
    listing.properties.find_or_create_by!(name: attrs[:name]) do |p|
      p.tenant   = mudcreek
      p.value    = attrs[:value]
      p.position = idx + 1
    end
  end
end

puts "Seeded listing properties."

# Rental listing
rental = Listing.find_or_create_by!(name: "Folding Tables & Chairs") do |l|
  l.tenant       = mudcreek
  l.listing_type = :rental
  l.price_cents  = 0
  l.description  = "Round folding tables (60\") and padded folding chairs available for events, estate viewings, and sales. Clean, stacked, and ready to go."
  l.published    = true
  l.owner_id     = admin_user.id
  l.state        = :on_sale
end

[
  { label: "2 Hours",  duration_minutes: 120,  price_cents: 2500  },
  { label: "Half Day", duration_minutes: 240,  price_cents: 4000  },
  { label: "Full Day", duration_minutes: 480,  price_cents: 6500  },
  { label: "Weekend",  duration_minutes: 1440, price_cents: 10000 }
].each do |attrs|
  rental.rental_rate_plans.find_or_create_by!(label: attrs[:label]) do |p|
    p.tenant           = mudcreek
    p.duration_minutes = attrs[:duration_minutes]
    p.price_cents      = attrs[:price_cents]
  end
end

puts "Seeded rental listing with #{rental.rental_rate_plans.count} rate plans."

# Assign listings to lots
lot_assignments = {
  "Henderson Estate" => [
    "Victorian Parlour Chair", "Oak Dining Table with Six Chairs", "Mahogany Dresser with Mirror",
    "Brass Bed Frame", "Antique Writing Desk", "Chesterfield Sofa", "Clockwork Mantle Clock",
    "Wedgwood Tea Service", "Sterling Silver Cutlery Set", "Silverplate Serving Tray",
    "Crystal Decanter Set", "Watercolour Landscape Painting", "Oil Portrait",
    "Framed Botanical Prints Set", "Gold Locket Necklace", "Pearl Bracelet",
    "Oak Roll-top Desk", "Mahogany Sideboard", "Walnut Bookcase with Glass Doors",
    "Swiss Cylinder Music Box", "Brass Aneroid Barometer", "Reverse Painting on Glass",
    "Needlework Sampler"
  ],
  "Blackwood Collection" => [
    "Brass Ship's Compass", "Pewter Tankard Set", "Bakelite Table Radio", "Gentleman's Pocket Watch",
    "Grundig Shortwave Radio", "8mm Film Projector", "Vintage Rotary Telephone",
    "Hand-painted China Plates", "Depression Glass Bowl Set", "Vintage Tin Advertising Signs",
    "Cast Iron Doorstop Collection", "Cameo Brooch", "Silver Cufflinks", "Amethyst Ring"
  ],
  "Greenfield Manor" => [
    "Tiffany-style Table Lamp", "Bronze Horse Figurine", "Hand-hooked Wool Rug",
    "Teak Garden Bench", "Cast Iron Garden Urns", "Copper Garden Lanterns",
    "Windsor Chairs Set of Four", "Cedar Chest", "Rocking Chair",
    "Copper Cookware Set", "Cast Iron Dutch Oven", "Mink Stole", "Men's Tweed Hunting Jacket",
    "Victorian Hall Tree", "Stone Garden Birdbath", "Wrought Iron Plant Stand",
    "Carved Wooden Duck Decoy"
  ],
  "Chapman Farm" => [
    "Stanley Hand Plane Set", "Woodworking Chisel Set", "Cast Iron Bench Vise",
    "Crosscut Hand Saw", "Vintage Level Set", "Antique Wheelbarrow",
    "Encyclopedia Britannica Set", "Vinyl Record Collection", "First Edition Poetry Collection",
    "Brace and Bit Set", "Drawknife", "National Geographic Collection", "Vintage Road Atlas Collection",
    "Stoneware Butter Churn", "Griswold Skillet Collection"
  ],
  "Personal Items" => [
    "Vintage Pyrex Mixing Bowl Set", "Beaded Evening Bag", "Vintage Hat Collection",
    "Vintage Tin Advertising Signs",
    "Lady's Victorian Brooch Set", "Edwardian Lace Collar", "Garnet Cluster Brooch",
    "Gold Watch Chain", "National Geographic Collection", "Vintage Road Atlas Collection"
  ]
}

lot_assignments.each do |lot_name, listing_names|
  lot = lots[lot_name]
  next unless lot
  listing_names.each do |listing_name|
    Listing.where(name: listing_name).update_all(lot_id: lot.id, owner_id: nil)
  end
end

puts "Assigned listings to lots."

# Listing Categories
category_names = [
  "Furniture",
  "Antiques & Collectibles",
  "Jewelry & Watches",
  "Tools & Workshop",
  "Books & Media",
  "Kitchenware & Dining",
  "Art & Decor",
  "Vintage Clothing",
  "Electronics",
  "Garden & Outdoor"
]

category_hero_images = {
  "Furniture"               => "cabin.jpg",
  "Antiques & Collectibles" => "homestead.jpg",
  "Jewelry & Watches"       => "sunset.jpg",
  "Tools & Workshop"        => "axe.jpg",
  "Books & Media"           => "lodge.jpg",
  "Kitchenware & Dining"    => "orchard.jpg",
  "Art & Decor"             => "river.jpg",
  "Vintage Clothing"        => "meadow.jpg",
  "Electronics"             => "bluff.jpg",
  "Garden & Outdoor"        => "farm.jpg"
}

categories = category_names.each_with_object({}) do |name, hash|
  hash[name] = Listings::Category.find_or_create_by!(name: name) do |c|
    c.tenant = mudcreek
  end
end

categories.each do |name, category|
  next if category.hero_image.attached?

  filename = category_hero_images[name]
  next unless filename

  path = Rails.root.join("spec/fixtures/images", filename)
  next unless path.exist?

  category.hero_image.attach(
    io:           path.open("rb"),
    filename:     filename,
    content_type: "image/jpeg"
  )
end

puts "Attached hero images to #{Listings::Category.joins(:hero_image_attachment).count} categories."

category_assignments = {
  # Furniture
  "Victorian Parlour Chair"         => [ "Furniture" ],
  "Oak Dining Table with Six Chairs" => [ "Furniture" ],
  "Mahogany Dresser with Mirror"    => [ "Furniture" ],
  "Brass Bed Frame"                 => [ "Furniture" ],
  "Antique Writing Desk"            => [ "Furniture", "Antiques & Collectibles" ],
  "Windsor Chairs Set of Four"      => [ "Furniture" ],
  "Cedar Chest"                     => [ "Furniture" ],
  "Chesterfield Sofa"               => [ "Furniture" ],
  "Teak Garden Bench"               => [ "Furniture", "Garden & Outdoor" ],
  "Rocking Chair"                   => [ "Furniture" ],
  # Antiques & Collectibles
  "Wedgwood Tea Service"            => [ "Antiques & Collectibles", "Kitchenware & Dining" ],
  "Bakelite Table Radio"            => [ "Antiques & Collectibles", "Electronics" ],
  "Clockwork Mantle Clock"          => [ "Antiques & Collectibles" ],
  "Depression Glass Bowl Set"       => [ "Antiques & Collectibles", "Kitchenware & Dining" ],
  "Sterling Silver Cutlery Set"     => [ "Antiques & Collectibles", "Kitchenware & Dining" ],
  "Vintage Tin Advertising Signs"   => [ "Antiques & Collectibles" ],
  "Pewter Tankard Set"              => [ "Antiques & Collectibles" ],
  "Brass Ship's Compass"            => [ "Antiques & Collectibles" ],
  "Hand-painted China Plates"       => [ "Antiques & Collectibles", "Kitchenware & Dining" ],
  "Cast Iron Doorstop Collection"   => [ "Antiques & Collectibles" ],
  # Jewelry & Watches
  "Gold Locket Necklace"            => [ "Jewelry & Watches" ],
  "Gentleman's Pocket Watch"        => [ "Jewelry & Watches", "Antiques & Collectibles" ],
  "Pearl Bracelet"                  => [ "Jewelry & Watches" ],
  "Cameo Brooch"                    => [ "Jewelry & Watches", "Antiques & Collectibles" ],
  "Silver Cufflinks"                => [ "Jewelry & Watches" ],
  "Amethyst Ring"                   => [ "Jewelry & Watches" ],
  # Tools & Workshop
  "Stanley Hand Plane Set"          => [ "Tools & Workshop" ],
  "Woodworking Chisel Set"          => [ "Tools & Workshop" ],
  "Cast Iron Bench Vise"            => [ "Tools & Workshop" ],
  "Crosscut Hand Saw"               => [ "Tools & Workshop" ],
  "Vintage Level Set"               => [ "Tools & Workshop", "Antiques & Collectibles" ],
  # Books & Media
  "Encyclopedia Britannica Set"     => [ "Books & Media" ],
  "Vinyl Record Collection"         => [ "Books & Media" ],
  "First Edition Poetry Collection" => [ "Books & Media", "Antiques & Collectibles" ],
  # Kitchenware & Dining
  "Copper Cookware Set"             => [ "Kitchenware & Dining" ],
  "Vintage Pyrex Mixing Bowl Set"   => [ "Kitchenware & Dining", "Antiques & Collectibles" ],
  "Crystal Decanter Set"            => [ "Kitchenware & Dining", "Antiques & Collectibles" ],
  "Silverplate Serving Tray"        => [ "Kitchenware & Dining", "Antiques & Collectibles" ],
  "Cast Iron Dutch Oven"            => [ "Kitchenware & Dining", "Antiques & Collectibles" ],
  # Art & Decor
  "Watercolour Landscape Painting"  => [ "Art & Decor" ],
  "Hand-hooked Wool Rug"            => [ "Art & Decor", "Antiques & Collectibles" ],
  "Framed Botanical Prints Set"     => [ "Art & Decor", "Antiques & Collectibles" ],
  "Bronze Horse Figurine"           => [ "Art & Decor" ],
  "Tiffany-style Table Lamp"        => [ "Art & Decor", "Antiques & Collectibles" ],
  "Oil Portrait"                    => [ "Art & Decor" ],
  # Vintage Clothing
  "Mink Stole"                      => [ "Vintage Clothing", "Antiques & Collectibles" ],
  "Men's Tweed Hunting Jacket"      => [ "Vintage Clothing" ],
  "Beaded Evening Bag"              => [ "Vintage Clothing", "Antiques & Collectibles" ],
  "Vintage Hat Collection"          => [ "Vintage Clothing" ],
  # Electronics
  "Grundig Shortwave Radio"         => [ "Electronics", "Antiques & Collectibles" ],
  "Vintage Rotary Telephone"        => [ "Electronics", "Antiques & Collectibles" ],
  "8mm Film Projector"              => [ "Electronics", "Antiques & Collectibles" ],
  # Garden & Outdoor
  "Cast Iron Garden Urns"           => [ "Garden & Outdoor", "Antiques & Collectibles" ],
  "Antique Wheelbarrow"             => [ "Garden & Outdoor", "Antiques & Collectibles" ],
  "Copper Garden Lanterns"          => [ "Garden & Outdoor" ],
  # Furniture (non-auction)
  "Oak Roll-top Desk"               => [ "Furniture", "Antiques & Collectibles" ],
  "Mahogany Sideboard"              => [ "Furniture", "Antiques & Collectibles" ],
  "Victorian Hall Tree"             => [ "Furniture", "Antiques & Collectibles" ],
  "Walnut Bookcase with Glass Doors" => [ "Furniture" ],
  # Antiques & Collectibles (non-auction)
  "Swiss Cylinder Music Box"        => [ "Antiques & Collectibles" ],
  "Dome-top Steamer Trunk"          => [ "Antiques & Collectibles" ],
  "Brass Aneroid Barometer"         => [ "Antiques & Collectibles" ],
  "Pressed Glass Compote Set"       => [ "Antiques & Collectibles", "Kitchenware & Dining" ],
  # Jewelry & Watches (non-auction)
  "Garnet Cluster Brooch"           => [ "Jewelry & Watches", "Antiques & Collectibles" ],
  "Gold Watch Chain"                => [ "Jewelry & Watches", "Antiques & Collectibles" ],
  # Tools & Workshop (non-auction)
  "Brace and Bit Set"               => [ "Tools & Workshop" ],
  "Drawknife"                       => [ "Tools & Workshop" ],
  # Books & Media (non-auction)
  "National Geographic Collection"  => [ "Books & Media" ],
  "Vintage Road Atlas Collection"   => [ "Books & Media", "Antiques & Collectibles" ],
  # Kitchenware & Dining (non-auction)
  "Stoneware Butter Churn"          => [ "Kitchenware & Dining", "Antiques & Collectibles" ],
  "Griswold Skillet Collection"     => [ "Kitchenware & Dining", "Antiques & Collectibles" ],
  # Art & Decor (non-auction)
  "Carved Wooden Duck Decoy"        => [ "Art & Decor", "Antiques & Collectibles" ],
  "Needlework Sampler"              => [ "Art & Decor", "Antiques & Collectibles" ],
  "Reverse Painting on Glass"       => [ "Art & Decor", "Antiques & Collectibles" ],
  # Vintage Clothing (non-auction)
  "Lady's Victorian Brooch Set"     => [ "Jewelry & Watches", "Vintage Clothing", "Antiques & Collectibles" ],
  "Edwardian Lace Collar"           => [ "Vintage Clothing", "Antiques & Collectibles" ],
  # Electronics (non-auction)
  "Underwood Typewriter"            => [ "Electronics", "Antiques & Collectibles" ],
  "Kodak Carousel Projector"        => [ "Electronics" ],
  # Garden & Outdoor (non-auction)
  "Stone Garden Birdbath"           => [ "Garden & Outdoor" ],
  "Wrought Iron Plant Stand"        => [ "Garden & Outdoor" ]
}

category_assignments.each do |listing_name, cat_names|
  listing = Listing.find_by(name: listing_name)
  next unless listing
  cat_names.each do |cat_name|
    cat = categories[cat_name]
    listing.categories << cat unless listing.categories.include?(cat)
  end
end

puts "Seeded #{Listings::Category.count} listing categories."

# Property Sets
property_set_data = [
  {
    name: "Books",
    properties: [
      { name: "Author",        value: "Ernest Hemingway",       icon: "bi-person-fill" },
      { name: "Publisher",     value: "Scribner",               icon: "bi-building" },
      { name: "Year",          value: "1952",                   icon: "bi-calendar3" },
      { name: "Edition",       value: "First Edition",          icon: "bi-journal-bookmark" },
      { name: "ISBN",          value: "978-0-684-80122-3",      icon: "bi-upc-scan" },
      { name: "Genre",         value: "Fiction",                icon: "bi-bookmark" },
      { name: "Condition",     value: "Good",                   icon: "bi-stars" }
    ]
  },
  {
    name: "Vinyl Records",
    properties: [
      { name: "Artist",        value: "Miles Davis",            icon: "bi-person-fill" },
      { name: "Album Title",   value: "Kind of Blue",           icon: "bi-vinyl-fill" },
      { name: "Label",         value: "Columbia",               icon: "bi-tag" },
      { name: "Release Year",  value: "1959",                   icon: "bi-calendar3" },
      { name: "Format",        value: "LP",                     icon: "bi-disc" },
      { name: "Speed",         value: "33 RPM",                 icon: "bi-speedometer2" },
      { name: "Condition",     value: "VG+",                    icon: "bi-stars" }
    ]
  },
  {
    name: "Vehicles",
    properties: [
      { name: "Make",          value: "Ford",                   icon: "bi-car-front-fill" },
      { name: "Model",         value: "F-100",                  icon: "bi-gear-fill" },
      { name: "Year",          value: "1967",                   icon: "bi-calendar3" },
      { name: "Colour",        value: "Poppy Red",              icon: "bi-palette2" },
      { name: "Mileage",       value: "87,400 miles",           icon: "bi-speedometer2" },
      { name: "Engine",        value: "360 FE V8",              icon: "bi-cpu-fill" },
      { name: "Transmission",  value: "3-speed manual",         icon: "bi-sliders2" },
      { name: "VIN",           value: "F10YK7A12345",           icon: "bi-hash" },
      { name: "Condition",     value: "Running, needs cosmetics", icon: "bi-stars" }
    ]
  },
  {
    name: "Farm Equipment",
    properties: [
      { name: "Make",          value: "John Deere",             icon: "bi-tools" },
      { name: "Model",         value: "4020",                   icon: "bi-gear-fill" },
      { name: "Year",          value: "1968",                   icon: "bi-calendar3" },
      { name: "Hours",         value: "4,200",                  icon: "bi-clock-history" },
      { name: "Serial Number", value: "T213R012345",            icon: "bi-hash" },
      { name: "Drive",         value: "2WD",                    icon: "bi-gear" },
      { name: "Condition",     value: "Field ready",            icon: "bi-stars" }
    ]
  },
  {
    name: "Paintings & Prints",
    properties: [
      { name: "Artist",        value: "E. Sutton",              icon: "bi-person-fill" },
      { name: "Title",         value: "River Valley at Dawn",   icon: "bi-journal-text" },
      { name: "Medium",        value: "Oil on canvas",          icon: "bi-brush-fill" },
      { name: "Dimensions",    value: "24\" × 30\"",            icon: "bi-rulers" },
      { name: "Year",          value: "1938",                   icon: "bi-calendar3" },
      { name: "Signed",        value: "Lower right",            icon: "bi-pen" },
      { name: "Framed",        value: "Yes — carved gilt",      icon: "bi-aspect-ratio" },
      { name: "Condition",     value: "Good; minor craquelure", icon: "bi-stars" }
    ]
  },
  {
    name: "Jewelry",
    properties: [
      { name: "Metal",         value: "Yellow gold",            icon: "bi-gem" },
      { name: "Karat",         value: "10K",                    icon: "bi-gem" },
      { name: "Gemstone",      value: "Amethyst",               icon: "bi-gem" },
      { name: "Weight",        value: "3.4 g",                  icon: "bi-scale" },
      { name: "Hallmarks",     value: "Birks, 10K",             icon: "bi-award" },
      { name: "Period",        value: "Victorian, c. 1890",     icon: "bi-clock-history" },
      { name: "Condition",     value: "Excellent",              icon: "bi-stars" }
    ]
  },
  {
    name: "Hand Tools",
    properties: [
      { name: "Manufacturer",  value: "Stanley",                icon: "bi-building" },
      { name: "Type",          value: "Bench plane",            icon: "bi-wrench" },
      { name: "Model",         value: "No. 5",                  icon: "bi-gear" },
      { name: "Size",          value: "14\" blade",             icon: "bi-rulers" },
      { name: "Material",      value: "Cast iron, rosewood",    icon: "bi-box" },
      { name: "Era",           value: "c. 1940s",               icon: "bi-hourglass" },
      { name: "Condition",     value: "Good; light surface rust", icon: "bi-stars" }
    ]
  },
  {
    name: "Furniture",
    properties: [
      { name: "Style",         value: "Victorian",              icon: "bi-house" },
      { name: "Primary Wood",  value: "Quarter-sawn oak",       icon: "bi-tree" },
      { name: "Dimensions",    value: "72\"H × 38\"W × 20\"D",  icon: "bi-rulers" },
      { name: "Hardware",      value: "Original brass",         icon: "bi-tools" },
      { name: "Finish",        value: "Original shellac",       icon: "bi-paint-bucket" },
      { name: "Joinery",       value: "Dovetailed",             icon: "bi-scissors" },
      { name: "Condition",     value: "Good; minor patina",     icon: "bi-stars" }
    ]
  },
  {
    name: "Clocks & Watches",
    properties: [
      { name: "Maker",         value: "Seth Thomas",            icon: "bi-building" },
      { name: "Movement",      value: "8-day, key-wind",        icon: "bi-gear" },
      { name: "Case Material", value: "Black slate and marble", icon: "bi-box" },
      { name: "Dial",          value: "Porcelain, Roman numerals", icon: "bi-clock" },
      { name: "Year",          value: "c. 1895",                icon: "bi-calendar3" },
      { name: "Running",       value: "Yes",                    icon: "bi-play-circle" },
      { name: "Condition",     value: "Good",                   icon: "bi-stars" }
    ]
  },
  {
    name: "Ceramics & Pottery",
    properties: [
      { name: "Maker",         value: "Wedgwood",               icon: "bi-building" },
      { name: "Pattern",       value: "Cornucopia",             icon: "bi-grid" },
      { name: "Glaze",         value: "Creamware",              icon: "bi-droplet" },
      { name: "Pieces",        value: "22",                     icon: "bi-stack" },
      { name: "Period",        value: "c. 1900",                icon: "bi-clock-history" },
      { name: "Marks",         value: "Wedgwood England impressed", icon: "bi-stamp" },
      { name: "Condition",     value: "No chips or cracks",     icon: "bi-stars" }
    ]
  },
  {
    name: "Silver & Silverplate",
    properties: [
      { name: "Pattern",       value: "Chantilly",              icon: "bi-grid" },
      { name: "Maker",         value: "Birks",                  icon: "bi-building" },
      { name: "Metal",         value: "Sterling (.925)",        icon: "bi-gem" },
      { name: "Hallmarks",     value: "Birks Sterling Canada",  icon: "bi-award" },
      { name: "Pieces",        value: "60",                     icon: "bi-stack" },
      { name: "Weight",        value: "2.1 kg",                 icon: "bi-scale" },
      { name: "Condition",     value: "Tarnished; polishes well", icon: "bi-stars" }
    ]
  },
  {
    name: "Cameras & Photography",
    properties: [
      { name: "Make",          value: "Leica",                  icon: "bi-camera-fill" },
      { name: "Model",         value: "M3",                     icon: "bi-gear" },
      { name: "Year",          value: "1955",                   icon: "bi-calendar3" },
      { name: "Film Format",   value: "35mm",                   icon: "bi-film" },
      { name: "Lens",          value: "Summicron 50mm f/2",     icon: "bi-camera2" },
      { name: "Serial Number", value: "700123",                 icon: "bi-hash" },
      { name: "Condition",     value: "Excellent; shutter works", icon: "bi-stars" }
    ]
  },
  {
    name: "Rugs & Textiles",
    properties: [
      { name: "Origin",        value: "Persia (Iran)",          icon: "bi-geo-alt-fill" },
      { name: "Type",          value: "Hand-knotted wool",      icon: "bi-grid3x3" },
      { name: "Dimensions",    value: "4' × 6'",                icon: "bi-rulers" },
      { name: "Pile",          value: "Wool on cotton warp",    icon: "bi-layers" },
      { name: "Age",           value: "c. 1920",                icon: "bi-hourglass" },
      { name: "Colours",       value: "Navy, ivory, rust",      icon: "bi-palette2" },
      { name: "Condition",     value: "Good; even wear",        icon: "bi-stars" }
    ]
  },
  {
    name: "Coins & Currency",
    properties: [
      { name: "Country",       value: "Canada",                 icon: "bi-flag-fill" },
      { name: "Denomination",  value: "50 cents",               icon: "bi-coin" },
      { name: "Year",          value: "1921",                   icon: "bi-calendar3" },
      { name: "Mint",          value: "Ottawa",                 icon: "bi-building" },
      { name: "Metal",         value: "80% silver",             icon: "bi-gem" },
      { name: "Grade",         value: "F-12",                   icon: "bi-award" },
      { name: "Notes",         value: "Key date",               icon: "bi-chat-text" }
    ]
  },
  {
    name: "Power Tools",
    properties: [
      { name: "Manufacturer",  value: "DeWalt",                 icon: "bi-building" },
      { name: "Model",         value: "DW618",                  icon: "bi-gear" },
      { name: "Type",          value: "Fixed-base router",      icon: "bi-plug-fill" },
      { name: "Voltage",       value: "120V",                   icon: "bi-lightning-fill" },
      { name: "Amperage",      value: "12A",                    icon: "bi-lightning-charge-fill" },
      { name: "Included",      value: "Collets, edge guide",    icon: "bi-box-seam" },
      { name: "Condition",     value: "Good; runs well",        icon: "bi-stars" }
    ]
  },
  {
    name: "Sporting & Outdoor",
    properties: [
      { name: "Type",          value: "Fly rod",                icon: "bi-activity" },
      { name: "Manufacturer",  value: "Hardy",                  icon: "bi-building" },
      { name: "Model",         value: "Palakona",               icon: "bi-gear" },
      { name: "Length",        value: "9'",                     icon: "bi-rulers" },
      { name: "Line Weight",   value: "#6",                     icon: "bi-bezier2" },
      { name: "Material",      value: "Split cane",             icon: "bi-box" },
      { name: "Condition",     value: "Good; original bag and tube", icon: "bi-stars" }
    ]
  },
  {
    name: "Lighting & Lamps",
    properties: [
      { name: "Style",         value: "Art Nouveau",            icon: "bi-brush" },
      { name: "Maker",         value: "Bradley & Hubbard",      icon: "bi-building" },
      { name: "Base Material", value: "Cast spelter",           icon: "bi-box" },
      { name: "Shade",         value: "Slag glass, 18\" dia.",  icon: "bi-lightbulb" },
      { name: "Height",        value: "24\"",                   icon: "bi-rulers" },
      { name: "Period",        value: "c. 1910",                icon: "bi-clock-history" },
      { name: "Condition",     value: "Very good; rewired",     icon: "bi-stars" }
    ]
  },
  {
    name: "Toys & Collectibles",
    properties: [
      { name: "Manufacturer",  value: "Dinky Toys",             icon: "bi-building" },
      { name: "Item",          value: "No. 139a Ford Fordor Sedan", icon: "bi-bag" },
      { name: "Year",          value: "c. 1948",                icon: "bi-calendar3" },
      { name: "Scale",         value: "1:43",                   icon: "bi-rulers" },
      { name: "Box",           value: "No",                     icon: "bi-box-seam" },
      { name: "Colour",        value: "Fawn",                   icon: "bi-palette2" },
      { name: "Condition",     value: "Good; minor paint wear", icon: "bi-stars" }
    ]
  },
  {
    name: "Militaria",
    properties: [
      { name: "Country",       value: "Canada",                 icon: "bi-flag-fill" },
      { name: "Branch",        value: "Royal Canadian Air Force", icon: "bi-shield-fill" },
      { name: "Period",        value: "Second World War",       icon: "bi-clock-history" },
      { name: "Item",          value: "Navigator's brevets",    icon: "bi-bag" },
      { name: "Markings",      value: "King's crown, RCAF",     icon: "bi-shield" },
      { name: "Provenance",    value: "With service record",    icon: "bi-file-earmark-text" },
      { name: "Condition",     value: "Very good",              icon: "bi-stars" }
    ]
  },
  {
    name: "Maps & Ephemera",
    properties: [
      { name: "Title",         value: "Map of the Province of British Columbia", icon: "bi-journal-text" },
      { name: "Cartographer",  value: "Dept. of Lands",         icon: "bi-map" },
      { name: "Date",          value: "1922",                   icon: "bi-calendar3" },
      { name: "Dimensions",    value: "32\" × 48\"",            icon: "bi-rulers" },
      { name: "Colour",        value: "Hand-coloured",          icon: "bi-palette2" },
      { name: "Condition",     value: "Good; folds as issued",  icon: "bi-stars" }
    ]
  },
  {
    name: "Musical Instruments",
    properties: [
      { name: "Type",          value: "Acoustic guitar",        icon: "bi-music-note-beamed" },
      { name: "Maker",         value: "Gibson",                 icon: "bi-building" },
      { name: "Model",         value: "J-45",                   icon: "bi-gear" },
      { name: "Year",          value: "1963",                   icon: "bi-calendar3" },
      { name: "Serial Number", value: "123456",                 icon: "bi-hash" },
      { name: "Finish",        value: "Sunburst",               icon: "bi-paint-bucket" },
      { name: "Case",          value: "Original hardshell",     icon: "bi-briefcase" },
      { name: "Condition",     value: "Good; plays well",       icon: "bi-stars" }
    ]
  },
  {
    name: "Glass & Crystal",
    properties: [
      { name: "Maker",         value: "Waterford",              icon: "bi-building" },
      { name: "Pattern",       value: "Lismore",                icon: "bi-grid" },
      { name: "Pieces",        value: "12",                     icon: "bi-stack" },
      { name: "Type",          value: "Wine glasses",           icon: "bi-cup" },
      { name: "Height",        value: "7\"",                    icon: "bi-rulers" },
      { name: "Marks",         value: "Waterford etched base",  icon: "bi-stamp" },
      { name: "Condition",     value: "Excellent; no chips",    icon: "bi-stars" }
    ]
  },
  {
    name: "Architectural Salvage",
    properties: [
      { name: "Type",          value: "Stained glass window",   icon: "bi-building" },
      { name: "Dimensions",    value: "24\" × 48\"",            icon: "bi-rulers" },
      { name: "Colours",       value: "Ruby, amber, clear",     icon: "bi-palette2" },
      { name: "Period",        value: "c. 1905",                icon: "bi-clock-history" },
      { name: "Origin",        value: "Church demolition, Ontario", icon: "bi-geo-alt-fill" },
      { name: "Frame",         value: "Lead came, oak surround", icon: "bi-aspect-ratio" },
      { name: "Condition",     value: "Good; one small crack",  icon: "bi-stars" }
    ]
  },
  {
    name: "Electronics & Radio",
    properties: [
      { name: "Manufacturer",  value: "RCA",                    icon: "bi-building" },
      { name: "Model",         value: "Victor 66X11",           icon: "bi-gear" },
      { name: "Type",          value: "Tabletop AM radio",      icon: "bi-radio" },
      { name: "Year",          value: "1946",                   icon: "bi-calendar3" },
      { name: "Cabinet",       value: "Bakelite, brown",        icon: "bi-box" },
      { name: "Working",       value: "Yes",                    icon: "bi-check-circle-fill" },
      { name: "Condition",     value: "Very good",              icon: "bi-stars" }
    ]
  },
  {
    name: "Native & Indigenous Art",
    properties: [
      { name: "Nation / Region", value: "Haida, British Columbia", icon: "bi-geo-alt-fill" },
      { name: "Artist",          value: "Unknown",              icon: "bi-person-fill" },
      { name: "Type",            value: "Argillite carving",    icon: "bi-brush" },
      { name: "Dimensions",      value: "6\" × 3\"",            icon: "bi-rulers" },
      { name: "Period",          value: "Early 20th century",   icon: "bi-clock-history" },
      { name: "Provenance",      value: "Private collection, Vancouver", icon: "bi-file-earmark-text" },
      { name: "Condition",       value: "Very good",            icon: "bi-stars" }
    ]
  },
  {
    name: "Vintage Clothing & Accessories",
    properties: [
      { name: "Type",          value: "Mink stole",             icon: "bi-bag" },
      { name: "Era",           value: "1950s",                  icon: "bi-hourglass" },
      { name: "Size",          value: "One size",               icon: "bi-rulers" },
      { name: "Colour",        value: "Natural brown",          icon: "bi-palette2" },
      { name: "Maker",         value: "Holt Renfrew",           icon: "bi-building" },
      { name: "Condition",     value: "Good; minor wear at clasp", icon: "bi-stars" }
    ]
  },
  {
    name: "Scientific & Medical",
    properties: [
      { name: "Type",          value: "Brass microscope",       icon: "bi-eyeglasses" },
      { name: "Maker",         value: "R. & J. Beck",           icon: "bi-building" },
      { name: "Model",         value: "No. 12",                 icon: "bi-gear" },
      { name: "Period",        value: "c. 1895",                icon: "bi-clock-history" },
      { name: "Objectives",    value: "1\", 2/3\", 1/5\"",      icon: "bi-eye" },
      { name: "Case",          value: "Original mahogany",      icon: "bi-briefcase" },
      { name: "Condition",     value: "Good; optics clear",     icon: "bi-stars" }
    ]
  }
]

property_set_data.each do |set_attrs|
  ps = Listings::PropertySet.find_or_create_by!(name: set_attrs[:name], tenant: mudcreek)
  set_attrs[:properties].each do |prop_attrs|
    ps.properties.find_or_create_by!(name: prop_attrs[:name]) do |p|
      p.tenant = mudcreek
      p.value  = prop_attrs[:value]
      p.icon   = prop_attrs[:icon]
    end
  end
end

puts "Seeded #{Listings::PropertySet.count} property sets with #{Listings::Property.where(listing_id: nil).count} template properties."

FIXTURES_IMAGE_DIR = Rails.root.join("spec/fixtures/images")

# Keywords (loremflickr.com tags) per listing — 2–3 variants give multiple images.
LISTING_IMAGE_KEYWORDS = {
  # Furniture
  "Victorian Parlour Chair"            => %w[antique-chair victorian-furniture parlour],
  "Oak Dining Table with Six Chairs"   => %w[antique-dining-table oak-furniture wooden-table],
  "Mahogany Dresser with Mirror"       => %w[antique-dresser vintage-mirror mahogany],
  "Brass Bed Frame"                    => %w[antique-brass-bed vintage-bedroom brass-bed],
  "Antique Writing Desk"               => %w[antique-desk writing-desk secretary-desk],
  "Windsor Chairs Set of Four"         => %w[windsor-chair antique-chair wooden-chair],
  "Cedar Chest"                        => %w[antique-chest cedar-chest vintage-trunk],
  "Chesterfield Sofa"                  => %w[chesterfield-sofa leather-sofa tufted-sofa],
  "Teak Garden Bench"                  => %w[garden-bench teak-bench outdoor-bench],
  "Rocking Chair"                      => %w[rocking-chair antique-rocker wooden-chair],

  # Antiques & Collectibles
  "Wedgwood Tea Service"               => %w[wedgwood-tea antique-tea-set porcelain-china],
  "Bakelite Table Radio"               => %w[vintage-radio bakelite-radio antique-radio],
  "Clockwork Mantle Clock"             => %w[mantle-clock antique-clock mantel-clock],
  "Depression Glass Bowl Set"          => %w[depression-glass vintage-glassware pink-glass],
  "Sterling Silver Cutlery Set"        => %w[silver-cutlery antique-silverware sterling-silver],
  "Vintage Tin Advertising Signs"      => %w[vintage-tin-sign antique-advertising tin-sign],
  "Pewter Tankard Set"                 => %w[pewter-tankard antique-tankard pewter-mug],
  "Brass Ship's Compass"               => %w[brass-compass nautical-compass ship-compass],
  "Hand-painted China Plates"          => %w[china-plates antique-china hand-painted-plate],
  "Cast Iron Doorstop Collection"      => %w[cast-iron antique-doorstop vintage-ironware],

  # Jewelry & Watches
  "Gold Locket Necklace"               => %w[gold-locket antique-jewelry vintage-necklace],
  "Gentleman's Pocket Watch"           => %w[pocket-watch antique-watch vintage-watch],
  "Pearl Bracelet"                     => %w[pearl-bracelet antique-jewelry vintage-bracelet],
  "Cameo Brooch"                       => %w[cameo-brooch antique-brooch vintage-jewelry],
  "Silver Cufflinks"                   => %w[silver-cufflinks antique-cufflinks menswear],
  "Amethyst Ring"                      => %w[amethyst-ring antique-ring vintage-gemstone],

  # Tools & Workshop
  "Stanley Hand Plane Set"             => %w[hand-plane woodworking-tools antique-tools],
  "Woodworking Chisel Set"             => %w[woodworking-chisel hand-tools wood-chisel],
  "Cast Iron Bench Vise"               => %w[bench-vise workshop-tools cast-iron-vise],
  "Crosscut Hand Saw"                  => %w[hand-saw vintage-saw woodworking-saw],
  "Vintage Level Set"                  => %w[spirit-level vintage-tools carpenter-tools],

  # Books & Media
  "Encyclopedia Britannica Set"        => %w[encyclopedia-books vintage-books library-shelf],
  "Vinyl Record Collection"            => %w[vinyl-records record-collection vintage-records],
  "First Edition Poetry Collection"    => %w[antique-books vintage-books old-books],

  # Kitchenware & Dining
  "Copper Cookware Set"                => %w[copper-cookware vintage-copper-pots kitchen-copper],
  "Vintage Pyrex Mixing Bowl Set"      => %w[pyrex-bowls vintage-kitchen mixing-bowls],
  "Crystal Decanter Set"               => %w[crystal-decanter glass-decanter crystal-glassware],
  "Silverplate Serving Tray"           => %w[silver-tray antique-tray silverplate-serving],
  "Cast Iron Dutch Oven"               => %w[cast-iron-dutch-oven griswold-cast-iron dutch-oven],

  # Art & Decor
  "Watercolour Landscape Painting"     => %w[watercolour-landscape antique-painting vintage-watercolor],
  "Hand-hooked Wool Rug"               => %w[vintage-rug hooked-rug antique-wool-rug],
  "Framed Botanical Prints Set"        => %w[botanical-prints antique-botanical vintage-prints],
  "Bronze Horse Figurine"              => %w[bronze-horse horse-figurine bronze-sculpture],
  "Tiffany-style Table Lamp"           => %w[tiffany-lamp stained-glass-lamp art-nouveau-lamp],
  "Oil Portrait"                       => %w[oil-portrait antique-portrait vintage-painting],

  # Vintage Clothing & Accessories
  "Mink Stole"                         => %w[mink-fur vintage-fur mink-stole],
  "Men's Tweed Hunting Jacket"         => %w[tweed-jacket harris-tweed vintage-jacket],
  "Beaded Evening Bag"                 => %w[beaded-bag antique-purse vintage-handbag],
  "Vintage Hat Collection"             => %w[vintage-hat antique-hats 1940s-hats],

  # Electronics
  "Grundig Shortwave Radio"            => %w[shortwave-radio vintage-radio grundig],
  "Vintage Rotary Telephone"           => %w[rotary-phone vintage-telephone dial-phone],
  "8mm Film Projector"                 => %w[8mm-projector vintage-projector film-projector],

  # Garden & Outdoor
  "Cast Iron Garden Urns"              => %w[garden-urn cast-iron-urn garden-planter],
  "Antique Wheelbarrow"                => %w[antique-wheelbarrow vintage-wheelbarrow garden],
  "Copper Garden Lanterns"             => %w[copper-lantern garden-lantern vintage-lantern],

  # Furniture (non-auction)
  "Oak Roll-top Desk"                  => %w[roll-top-desk antique-desk cylinder-desk],
  "Mahogany Sideboard"                 => %w[antique-sideboard mahogany-buffet vintage-sideboard],
  "Victorian Hall Tree"                => %w[hall-tree coat-stand antique-hallway],
  "Walnut Bookcase with Glass Doors"   => %w[antique-bookcase barrister-bookcase glass-bookcase],

  # Antiques & Collectibles (non-auction)
  "Swiss Cylinder Music Box"           => %w[antique-music-box cylinder-music-box vintage-music],
  "Dome-top Steamer Trunk"             => %w[steamer-trunk antique-trunk vintage-chest],
  "Brass Aneroid Barometer"            => %w[antique-barometer brass-barometer weather-instrument],
  "Pressed Glass Compote Set"          => %w[pressed-glass antique-glassware hobstar-glass],

  # Jewelry & Watches (non-auction)
  "Garnet Cluster Brooch"              => %w[garnet-brooch antique-brooch victorian-jewelry],
  "Gold Watch Chain"                   => %w[gold-watch-chain albert-chain antique-chain],

  # Tools & Workshop (non-auction)
  "Brace and Bit Set"                  => %w[brace-and-bit antique-brace woodworking-brace],
  "Drawknife"                          => %w[drawknife antique-drawknife woodworking-tools],

  # Books & Media (non-auction)
  "National Geographic Collection"     => %w[national-geographic vintage-magazines magazine-collection],
  "Vintage Road Atlas Collection"      => %w[vintage-road-map antique-atlas old-maps],

  # Kitchenware & Dining (non-auction)
  "Stoneware Butter Churn"             => %w[butter-churn stoneware-churn antique-crock],
  "Griswold Skillet Collection"        => %w[griswold-cast-iron cast-iron-skillet vintage-skillet],

  # Art & Decor (non-auction)
  "Carved Wooden Duck Decoy"           => %w[duck-decoy carved-decoy antique-decoy],
  "Needlework Sampler"                 => %w[needlework-sampler antique-sampler embroidery-sampler],
  "Reverse Painting on Glass"          => %w[reverse-painting antique-glass-painting chinese-export-art],

  # Vintage Clothing (non-auction)
  "Lady's Victorian Brooch Set"        => %w[victorian-brooch antique-brooch vintage-pin],
  "Edwardian Lace Collar"              => %w[antique-lace edwardian-collar lace-collar],

  # Electronics (non-auction)
  "Underwood Typewriter"               => %w[underwood-typewriter antique-typewriter vintage-typewriter],
  "Kodak Carousel Projector"           => %w[kodak-projector carousel-projector slide-projector],

  # Garden & Outdoor (non-auction)
  "Stone Garden Birdbath"              => %w[garden-birdbath stone-birdbath garden-ornament],
  "Wrought Iron Plant Stand"           => %w[plant-stand wrought-iron-stand garden-stand]
}.freeze

# Download a loremflickr image and cache it under spec/fixtures/images/listings/.
# Returns the Pathname, or nil on failure.
def fetch_listing_image(keyword, filename)
  require "net/http"
  cache_dir = FIXTURES_IMAGE_DIR.join("listings")
  cache_dir.mkpath
  cached = cache_dir.join(filename)
  return cached if cached.exist?

  uri = URI("https://loremflickr.com/800/600/#{keyword}")
  10.times do
    path = uri.path.then { |p| uri.query ? "#{p}?#{uri.query}" : p }
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.get(path, "User-Agent" => "MudCreek Seeds/1.0")
    end
    case response
    when Net::HTTPSuccess
      cached.binwrite(response.body)
      return cached
    when Net::HTTPRedirection
      uri = URI.join(uri, response["location"])
    else
      raise "HTTP #{response.code}"
    end
  end
  raise "Too many redirects"
rescue => e
  puts "  Image download failed (#{keyword}): #{e.message}"
  nil
end

listing_images_attached = 0
listing_images_skipped  = 0

LISTING_IMAGE_KEYWORDS.each do |listing_name, keywords|
  listing = Listing.find_by(name: listing_name)
  next unless listing

  existing_count = listing.images.count
  keywords.each_with_index do |keyword, idx|
    next if idx < existing_count  # skip already-attached slots

    safe_name = listing_name.gsub(/[^a-zA-Z0-9]/, "_").downcase
    filename  = "#{safe_name}_#{idx + 1}.jpg"
    cache_hit = FIXTURES_IMAGE_DIR.join("listings", filename).exist?
    print "  [#{listing_images_attached + listing_images_skipped + 1}/#{LISTING_IMAGE_KEYWORDS.sum { |_, kw| kw.size }}] #{listing_name} (#{keyword})#{cache_hit ? " [cached]" : ""}... "
    $stdout.flush
    path = fetch_listing_image(keyword, filename)

    if path
      listing.images.attach(
        io:           path.open("rb"),
        filename:     filename,
        content_type: "image/jpeg"
      )
      listing_images_attached += 1
      puts "ok"
    else
      listing_images_skipped += 1
      puts "failed"
    end
  end
end

puts "Attached #{listing_images_attached} listing images (#{listing_images_skipped} skipped due to download errors)."

# Offers
Current.tenant = mudcreek
if Rails.env.development? || Rails.env.test?
  buyer_ids = User.where(tenant: mudcreek).where.not(email_address: "admin@mudcreek.com").pluck(:id)
  negotiable_listings = Listing.where(tenant: mudcreek, pricing_type: :negotiable).to_a

  offer_data = [
    { listing: "Victorian Parlour Chair",      amount: 165, message: "Lovely piece — would you take a little less?", state: :pending },
    { listing: "Victorian Parlour Chair",      amount: 175, message: "Cash, can pick up this weekend.",              state: :pending },

    { listing: "Mahogany Dresser with Mirror", amount: 290, message: "Interested, is there any flex?",              state: :declined },
    { listing: "Mahogany Dresser with Mirror", amount: 310, message: "Final offer from a keen buyer.",              state: :accepted },

    { listing: "Watercolour Landscape Painting", amount: 195, message: "Beautiful work — room to move?",           state: :pending },
    { listing: "Watercolour Landscape Painting", amount: 210, message: "Happy to pay in cash on collection.",      state: :pending },

    { listing: "Gentleman's Pocket Watch",    amount: 250, message: "Great watch, hoping for a bit of a deal.",    state: :declined },
    { listing: "Gentleman's Pocket Watch",    amount: 270, message: "Serious collector, will take it today.",      state: :accepted },

    { listing: "Mink Stole",                  amount: 130, message: "Excellent condition — any flexibility?",      state: :pending },

    { listing: "Bakelite Table Radio",        amount: 70,  message: "Would $70 work?",                             state: :declined },
    { listing: "Bakelite Table Radio",        amount: 80,  message: "Willing to meet halfway.",                    state: :pending },

    { listing: "Tiffany-style Table Lamp",    amount: 255, message: "Love it — best I can do is $255.",            state: :pending },
    { listing: "Tiffany-style Table Lamp",    amount: 270, message: "I'll arrange courier if you accept.",         state: :pending },

    { listing: "Chesterfield Sofa",           amount: 450, message: "Could you do $450? I have a truck.",          state: :pending },

    { listing: "Antique Writing Desk",        amount: 340, message: "Interested if there's a bit of flex.",        state: :declined },
    { listing: "Antique Writing Desk",        amount: 360, message: "Ready to move quickly.",                      state: :pending }
  ]

  offer_data.each do |attrs|
    listing = negotiable_listings.find { |l| l.name == attrs[:listing] }
    next unless listing

    offer = Offer.create!(
      tenant: mudcreek,
      listing: listing,
      user_id: buyer_ids.sample,
      amount_cents: attrs[:amount] * 100,
      message: attrs[:message],
      state: :pending
    )
    offer.update!(state: attrs[:state]) if attrs[:state] != :pending
  end

  puts "Seeded #{Offer.count} offers."
end

# Discount Codes
DiscountCode.destroy_all

[
  { key: "WELCOME10",  discount_type: :fixed,      amount_cents: 1_000, start_at: nil,              end_at: nil },
  { key: "SAVE25",     discount_type: :fixed,      amount_cents: 2_500, start_at: nil,              end_at: nil },
  { key: "SUMMER15",   discount_type: :percentage, amount_cents: 1_500, start_at: nil,              end_at: 1.month.from_now },
  { key: "FALL10",     discount_type: :percentage, amount_cents: 1_000, start_at: nil,              end_at: nil },
  { key: "EARLYBIRD",  discount_type: :fixed,      amount_cents: 5_000, start_at: nil,              end_at: 2.weeks.from_now },
  { key: "EXPIRED20",  discount_type: :percentage, amount_cents: 2_000, start_at: 3.months.ago,    end_at: 1.month.ago },
  { key: "FUTURE50",   discount_type: :fixed,      amount_cents: 5_000, start_at: 1.month.from_now, end_at: 2.months.from_now }
].each do |attrs|
  DiscountCode.find_or_create_by!(key: attrs[:key]) do |dc|
    dc.tenant        = mudcreek
    dc.discount_type = attrs[:discount_type]
    dc.amount_cents  = attrs[:amount_cents]
    dc.start_at      = attrs[:start_at]
    dc.end_at        = attrs[:end_at]
  end
end

puts "Seeded #{DiscountCode.count} discount codes."

# Delivery Methods
[
  { name: "Local Pickup",  price_cents: 0,    address_required: false },
  { name: "Standard Mail", price_cents: 1500, address_required: true  },
  { name: "Courier",       price_cents: 2500, address_required: true  }
].each do |attrs|
  DeliveryMethod.find_or_create_by!(name: attrs[:name], tenant: mudcreek) do |dm|
    dm.price_cents      = attrs[:price_cents]
    dm.address_required = attrs[:address_required]
    dm.active           = true
  end
end

puts "Seeded #{DeliveryMethod.count} delivery methods."

# Delivery Method Sets
pickup  = DeliveryMethod.find_by!(name: "Local Pickup",  tenant: mudcreek)
mail    = DeliveryMethod.find_by!(name: "Standard Mail", tenant: mudcreek)
courier = DeliveryMethod.find_by!(name: "Courier",       tenant: mudcreek)

[
  { name: "Standard",    methods: [ pickup, mail, courier ] },
  { name: "No pickup",   methods: [ mail, courier ] },
  { name: "Pickup only", methods: [ pickup ] }
].each do |attrs|
  set = Listings::DeliveryMethodSet.find_or_create_by!(name: attrs[:name], tenant: mudcreek)
  attrs[:methods].each do |dm|
    set.deliveries.find_or_create_by!(delivery_method: dm, tenant: mudcreek)
  end
end

puts "Seeded #{Listings::DeliveryMethodSet.count} delivery method sets."

# Default Bid Increment Schedule
Current.tenant = mudcreek
schedule = BidIncrementSchedule.find_or_create_by!(auction_id: nil)
schedule.tiers.destroy_all
[
  { min_amount_cents:       0, increment_cents:   500 },  # $0+      → $5
  { min_amount_cents:  10_000, increment_cents: 1_000 },  # $100+    → $10
  { min_amount_cents:  25_000, increment_cents: 2_500 },  # $250+    → $25
  { min_amount_cents:  50_000, increment_cents: 5_000 },  # $500+    → $50
  { min_amount_cents: 100_000, increment_cents: 10_000 }  # $1,000+  → $100
].each do |attrs|
  schedule.tiers.create!(attrs)
end
puts "Seeded default bid increment schedule with #{schedule.tiers.count} tiers."
Current.tenant = nil

# Auctions
AuctionListing.destroy_all
Auction.destroy_all

auction_data = [
  {
    name: "Henderson Estate Auction",
    starts_at: 6.weeks.ago,
    ends_at: 4.weeks.ago,
    end_time_stagger_interval: 60,
    published: true,
    reconciled: true,
    auto_approve: false,
    poster: "homestead.jpg",
    address: { street_address: "412 Elmwood Avenue", city: "Kamloops", province: "BC", postal_code: "V2C 1A1", country: "CA", latitude: 50.6745, longitude: -120.3273 },
    listings: [
      { name: "Victorian Parlour Chair",        starting_bid: 100, bid_increment: 10, reserve_price: 150 },
      { name: "Mahogany Dresser with Mirror",   starting_bid: 200, bid_increment: 20, reserve_price: 280 },
      { name: "Clockwork Mantle Clock",         starting_bid: 100, bid_increment: 10, reserve_price: 175 },
      { name: "Crystal Decanter Set",           starting_bid:  50, bid_increment: 10, reserve_price: nil },
      { name: "Watercolour Landscape Painting", starting_bid: 125, bid_increment: 25, reserve_price: nil }
    ]
  },
  {
    name: "Blackwood Collection Sale",
    starts_at: 3.days.ago,
    ends_at: 11.days.from_now,
    end_time_stagger_interval: 30,
    published: true,
    reconciled: false,
    auto_approve: true,
    poster: "lodge.jpg",
    address: { street_address: "88 Birchwood Court", city: "Revelstoke", province: "BC", postal_code: "V0E 2S0", country: "CA", latitude: 50.9981, longitude: -118.1955 },
    listings: [
      { name: "Gentleman's Pocket Watch",     starting_bid: 150, bid_increment: 25, reserve_price: 250 },
      { name: "Sterling Silver Cutlery Set",  starting_bid: 150, bid_increment: 25, reserve_price: nil },
      { name: "Tiffany-style Table Lamp",     starting_bid: 150, bid_increment: 25, reserve_price: 250 },
      { name: "Bronze Horse Figurine",        starting_bid:  75, bid_increment: 15, reserve_price: nil },
      { name: "Hand-hooked Wool Rug",         starting_bid: 100, bid_increment: 15, reserve_price: 165 }
    ]
  },
  {
    name: "Greenfield Manor Preview",
    starts_at: 3.weeks.from_now,
    ends_at: 5.weeks.from_now,
    published: false,
    reconciled: false,
    auto_approve: true,
    poster: "meadow.jpg",
    address: { street_address: "55 Manor Gate Road", city: "Penticton", province: "BC", postal_code: "V2A 1B3", country: "CA", latitude: 49.4897, longitude: -119.5853 },
    listings: [
      { name: "Vinyl Record Collection", starting_bid: 40,  bid_increment: 5,  reserve_price: nil },
      { name: "Grundig Shortwave Radio", starting_bid: 50,  bid_increment: 10, reserve_price: nil },
      { name: "Bakelite Table Radio",    starting_bid: 35,  bid_increment: 5,  reserve_price: nil },
      { name: "Oil Portrait",            starting_bid: 100, bid_increment: 15, reserve_price: 175 }
    ]
  },
  {
    name: "Lakeview Cottage Dispersal",
    starts_at: 5.days.ago,
    ends_at: 9.days.from_now,
    end_time_stagger_interval: 45,
    published: true,
    reconciled: false,
    auto_approve: true,
    poster: "lake.jpg",
    address: { street_address: "14 Lakeshore Drive", city: "Salmon Arm", province: "BC", postal_code: "V1E 2V1", country: "CA", latitude: 50.7021, longitude: -119.2778 },
    listings: [
      { name: "Teak Garden Bench",          starting_bid:  75, bid_increment: 10, reserve_price: nil },
      { name: "Cast Iron Garden Urns",      starting_bid:  75, bid_increment: 15, reserve_price: 140 },
      { name: "Copper Garden Lanterns",     starting_bid:  50, bid_increment: 10, reserve_price: nil },
      { name: "Copper Cookware Set",        starting_bid: 100, bid_increment: 15, reserve_price: 160 },
      { name: "Vintage Pyrex Mixing Bowl Set", starting_bid: 35, bid_increment: 5, reserve_price: nil }
    ]
  },
  {
    name: "Ranch & Farm Consignment",
    starts_at: 8.days.ago,
    ends_at: 6.days.from_now,
    end_time_stagger_interval: 30,
    published: true,
    reconciled: false,
    auto_approve: true,
    poster: "ranch.jpg",
    address: { street_address: "9900 Douglas Lake Road", city: "Merritt", province: "BC", postal_code: "V1K 1P0", country: "CA", latitude: 50.1138, longitude: -120.7882 },
    listings: [
      { name: "Antique Wheelbarrow",    starting_bid: 45,  bid_increment: 5,  reserve_price: nil },
      { name: "Vintage Level Set",      starting_bid: 20,  bid_increment: 5,  reserve_price: nil },
      { name: "Crosscut Hand Saw",      starting_bid: 20,  bid_increment: 5,  reserve_price: nil },
      { name: "Woodworking Chisel Set", starting_bid: 30,  bid_increment: 5,  reserve_price: nil },
      { name: "Cast Iron Dutch Oven",   starting_bid: 35,  bid_increment: 5,  reserve_price: nil }
    ]
  },
  {
    name: "Prairie Homestead Collection",
    starts_at: 10.weeks.ago,
    ends_at: 8.weeks.ago,
    end_time_stagger_interval: 0,
    published: true,
    reconciled: true,
    auto_approve: false,
    poster: "prairie.jpg",
    address: { street_address: "Rural Route 3", city: "Ashcroft", province: "BC", postal_code: "V0K 1A0", country: "CA", latitude: 50.7271, longitude: -121.2836 },
    listings: [
      { name: "Cedar Chest",                starting_bid:  75, bid_increment: 10, reserve_price: nil },
      { name: "Windsor Chairs Set of Four", starting_bid: 100, bid_increment: 15, reserve_price: nil },
      { name: "Rocking Chair",              starting_bid:  50, bid_increment: 10, reserve_price: nil },
      { name: "Mink Stole",                 starting_bid:  75, bid_increment: 15, reserve_price: 120 },
      { name: "Men's Tweed Hunting Jacket", starting_bid:  40, bid_increment: 10, reserve_price: nil },
      { name: "Beaded Evening Bag",         starting_bid:  25, bid_increment: 5,  reserve_price: nil },
      { name: "Vintage Hat Collection",     starting_bid:  30, bid_increment: 5,  reserve_price: nil }
    ]
  },
  {
    name: "Orchard Valley Estate",
    starts_at: 2.weeks.from_now,
    ends_at: 4.weeks.from_now,
    end_time_stagger_interval: 60,
    published: true,
    reconciled: false,
    auto_approve: true,
    poster: "orchard.jpg",
    address: { street_address: "1250 Orchard Road", city: "Kelowna", province: "BC", postal_code: "V1Y 5A1", country: "CA", latitude: 49.8880, longitude: -119.4960 },
    listings: [
      { name: "Chesterfield Sofa",          starting_bid: 250, bid_increment: 25, reserve_price: 400 },
      { name: "Antique Writing Desk",       starting_bid: 175, bid_increment: 25, reserve_price: nil },
      { name: "Brass Bed Frame",            starting_bid: 125, bid_increment: 25, reserve_price: nil },
      { name: "Gold Locket Necklace",       starting_bid:  75, bid_increment: 15, reserve_price: nil },
      { name: "Pearl Bracelet",             starting_bid:  50, bid_increment: 10, reserve_price: nil },
      { name: "Cameo Brooch",               starting_bid:  35, bid_increment: 5,  reserve_price: nil },
      { name: "Silver Cufflinks",           starting_bid:  30, bid_increment: 5,  reserve_price: nil },
      { name: "Framed Botanical Prints Set", starting_bid: 40, bid_increment: 10, reserve_price: nil }
    ]
  }
]

auctions = auction_data.map do |attrs|
  auction = Auction.create!(
    tenant: mudcreek,
    name: attrs[:name],
    starts_at: attrs[:starts_at],
    ends_at: attrs[:ends_at],
    end_time_stagger_interval: attrs[:end_time_stagger_interval] || 0,
    published: attrs[:published],
    reconciled: attrs[:reconciled],
    auto_approve: attrs[:auto_approve]
  )

  addr = attrs[:address]
  Address.create!(
    addressable: auction,
    address_type: "primary",
    street_address: addr[:street_address],
    city: addr[:city],
    province: addr[:province],
    postal_code: addr[:postal_code],
    country: addr[:country],
    latitude: addr[:latitude],
    longitude: addr[:longitude]
  )

  attrs[:listings].each_with_index do |listing_attrs, idx|
    listing = Listing.find_by(name: listing_attrs[:name])
    next unless listing

    AuctionListing.create!(
      auction: auction,
      listing: listing,
      position: idx + 1,
      starting_bid_cents:  listing_attrs[:starting_bid] * 100,
      reserve_price_cents: listing_attrs[:reserve_price] ? listing_attrs[:reserve_price] * 100 : nil
    )
  end

  if attrs[:poster] && !auction.poster.attached?
    poster_path = FIXTURES_IMAGE_DIR.join(attrs[:poster])
    auction.poster.attach(
      io: poster_path.open("rb"),
      filename: attrs[:poster],
      content_type: "image/jpeg"
    )
  end

  auction
end

puts "Seeded #{Auction.count} auctions with #{AuctionListing.count} auction listings."

# Auction Registrations
Current.tenant = mudcreek
if Rails.env.local?
  regular_users = User.where(tenant: mudcreek).where.not(email_address: "admin@mudcreek").limit(10).to_a

  if regular_users.any?
    henderson_auction, blackwood_auction, greenfield_auction = auctions

    # Henderson (past, reconciled, manual approve) — mix of states
    regular_users.first(4).each_with_index do |user, i|
      state = [ :approved, :approved, :approved, :rejected ][i]
      AuctionRegistration.create!(auction: henderson_auction, user: user, state: state)
    end

    # Blackwood (live, auto_approve: true) — all approved automatically
    regular_users.first(7).each do |user|
      AuctionRegistration.new(auction: blackwood_auction, user: user).save!
    end

    # Greenfield (upcoming) — a few registered early
    regular_users.first(3).each do |user|
      AuctionRegistration.create!(auction: greenfield_auction, user: user)
    end

    puts "Seeded #{AuctionRegistration.count} auction registrations."

    # Bids for the Henderson Estate Auction (past, reconciled)
    henderson_listings = henderson_auction.auction_listings.order(:position).to_a
    approved_regs      = henderson_auction.auction_registrations.where(state: :approved).to_a

    if approved_regs.size >= 2 && henderson_listings.any?
      Bid.where(auction_listing: henderson_listings).delete_all

      bid_scripts = [
        # Victorian Parlour Chair — 6 bids, 1 extension, competitive finish
        {
          listing_index: 0,
          extension_count: 1,
          bids: [
            { reg_index: 0, amount_cents: 10_000 },
            { reg_index: 1, amount_cents: 11_000 },
            { reg_index: 0, amount_cents: 12_000 },
            { reg_index: 1, amount_cents: 13_000 },
            { reg_index: 0, amount_cents: 14_000 },
            { reg_index: 1, amount_cents: 16_500 }
          ]
        },
        # Mahogany Dresser with Mirror — 8 bids, 2 extensions, three-way contest
        {
          listing_index: 1,
          extension_count: 2,
          bids: [
            { reg_index: 0, amount_cents: 20_000 },
            { reg_index: 1, amount_cents: 22_000 },
            { reg_index: 2, amount_cents: 24_000 },
            { reg_index: 0, amount_cents: 26_000 },
            { reg_index: 1, amount_cents: 28_000 },
            { reg_index: 2, amount_cents: 30_000 },
            { reg_index: 0, amount_cents: 32_000 },
            { reg_index: 1, amount_cents: 34_000 }
          ]
        },
        # Clockwork Mantle Clock — 4 bids, no extensions
        {
          listing_index: 2,
          extension_count: 0,
          bids: [
            { reg_index: 1, amount_cents: 10_000 },
            { reg_index: 0, amount_cents: 11_000 },
            { reg_index: 1, amount_cents: 13_000 },
            { reg_index: 0, amount_cents: 17_500 }
          ]
        },
        # Crystal Decanter Set — 3 bids, no extensions, single winner
        {
          listing_index: 3,
          extension_count: 0,
          bids: [
            { reg_index: 2, amount_cents: 5_000 },
            { reg_index: 0, amount_cents: 6_000 },
            { reg_index: 2, amount_cents: 7_500 }
          ]
        },
        # Watercolour Landscape Painting — no bids (didn't reach reserve)
        {
          listing_index: 4,
          extension_count: 0,
          bids: []
        }
      ]

      bid_scripts.each do |script|
        al = henderson_listings[script[:listing_index]]
        next unless al

        al.update_column(:extension_count, script[:extension_count])

        script[:bids].each do |bid_attrs|
          reg = approved_regs[bid_attrs[:reg_index]]
          next unless reg

          Bid.new(
            auction_listing:      al,
            auction_registration: reg,
            amount_cents:         bid_attrs[:amount_cents],
            state:                :placed
          ).save!(validate: false)
        end
      end

      puts "Seeded #{Bid.count} bids for Henderson Estate Auction."
    end
  end
end

# Invoices for the super_admin user
Invoice.destroy_all

# Past auction used only for a paid invoice seed
chapman_tools_auction = Auction.find_or_create_by!(name: "Chapman Farm Tools Sale") do |a|
  a.tenant                  = mudcreek
  a.starts_at               = 10.weeks.ago
  a.ends_at                 = 8.weeks.ago
  a.end_time_stagger_interval = 0
  a.bidding_extension       = 0
  a.published               = true
  a.reconciled              = true
  a.auto_approve            = false
end

unless chapman_tools_auction.poster.attached?
  chapman_tools_auction.poster.attach(
    io: FIXTURES_IMAGE_DIR.join("farm.jpg").open("rb"),
    filename: "farm.jpg",
    content_type: "image/jpeg"
  )
end

henderson_auction = Auction.find_by!(name: "Henderson Estate Auction")

# Unpaid invoice — Henderson Estate Auction
invoice_unpaid = Invoice.create!(
  tenant:       mudcreek,
  user:         admin_user,
  auction:      henderson_auction,
  total_cents:  41500
)

[
  { name: "Victorian Parlour Chair",       amount_cents: 16_500 },
  { name: "Clockwork Mantle Clock",        amount_cents: 17_500 },
  { name: "Crystal Decanter Set",          amount_cents:  7_500 }
].each do |attrs|
  invoice_unpaid.invoice_items.create!(
    listing:      Listing.find_by(name: attrs[:name]),
    name:         attrs[:name],
    amount_cents: attrs[:amount_cents]
  )
end

# Paid invoice — Chapman Farm Tools Sale
invoice_paid = Invoice.create!(
  tenant:       mudcreek,
  user:         admin_user,
  auction:      chapman_tools_auction,
  total_cents:  18_000,
  status:       :paid
)

[
  { name: "Stanley Hand Plane Set", amount_cents: 9_000 },
  { name: "Cast Iron Bench Vise",   amount_cents: 9_000 }
].each do |attrs|
  invoice_paid.invoice_items.create!(
    listing:      Listing.find_by(name: attrs[:name]),
    name:         attrs[:name],
    amount_cents: attrs[:amount_cents]
  )
end

puts "Seeded #{Invoice.count} invoices with #{InvoiceItem.count} invoice items."

# Pages
Current.tenant = mudcreek

about_page = Page.find_or_create_by!(slug: "about") do |p|
  p.title          = "About Us"
  p.published      = true
  p.show_in_nav    = true
  p.show_in_footer = true
  p.position       = 1
  p.body           = <<~HTML
    <h2>Welcome to Mudcreek Auctions &amp; Consignment</h2>
    <p>Mudcreek is a family-owned auction house serving the Kamloops region since 1998. We specialize in estate sales, farm equipment, tools, antiques, and general consignment.</p>
    <h3>How It Works</h3>
    <p>Browse our upcoming auctions and listings online. Register for free to bid, make offers, or add items to your watchlist. Winners are notified by email and can arrange pickup or delivery.</p>
    <h3>Consign With Us</h3>
    <p>Have items to sell? We accept consignments year-round. Contact us to schedule a free appraisal and get your items in front of thousands of registered bidders.</p>
    <h3>Contact</h3>
    <p>101 River Road, Kamloops, BC V2C 2A1<br>Phone: (250) 555-0198<br>Email: info@mudcreekauctions.com</p>
  HTML
end

unless about_page.left_column_image.attached?
  about_page.left_column_image.attach(
    io:           Rails.root.join("spec/fixtures/images/river.jpg").open("rb"),
    filename:     "river.jpg",
    content_type: "image/jpeg"
  )
end

Current.tenant = nil

puts "Seeded #{Page.count} pages."
