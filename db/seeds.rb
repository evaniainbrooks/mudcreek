default_password = Rails.application.credentials&.seeds&.default_user_password || "default"

# Tenants
mudcreek = Tenant.find_or_create_by!(key: "mudcreek") do |t|
  t.name = "Mudcreek"
  t.default = true
end

Tenant.find_or_create_by!(key: "whitelabel") do |t|
  t.name = "Whitelabel"
  t.default = false
end

unless mudcreek.logo.attached?
  mudcreek.logo.attach(
    io: Rails.root.join("spec/fixtures/images/mudcreek_logo.png").open("rb"),
    filename: "mudcreek_logo.png",
    content_type: "image/png"
  )
end

puts "Seeded #{Tenant.count} tenants."

# Backfill any existing records that predate the tenant column
[ Role, Permission, User, Listing, Listings::Category, CartItem ].each do |klass|
  count = klass.where(tenant_id: nil).update_all(tenant_id: mudcreek.id)
  puts "Backfilled #{count} #{klass.name} records to mudcreek tenant." if count > 0
end

# Roles & Permissions
all_resources = %w[
  Listing Lot User Role Permission Listings::Category Offer Order DiscountCode DeliveryMethod Listings::RentalRatePlan Auction AuctionListing Tenant AuctionRegistration Bid
]

all_actions = %w[index show create update destroy reorder]

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

all_resources.each do |resource|
  all_actions.each do |action|
    super_admin.permissions.find_or_create_by!(resource: resource, action: action) do |p|
      p.tenant = mudcreek
    end
  end
end

admin_resources = %w[Listing Auction Lot Listings::Category Offer DiscountCode DeliveryMethod Listings::RentalRatePlan AuctionListing AuctionRegistration]
admin_resources.each do |resource|
  all_actions.each do |action|
    admin.permissions.find_or_create_by!(resource: resource, action: action) do |p|
      p.tenant = mudcreek
    end
  end
end

puts "Seeded #{Role.count} roles and #{Permission.count} permissions."

Offer.destroy_all
CartItem.destroy_all
Lot.destroy_all
User.destroy_all

User.create!(
  tenant: mudcreek,
  email_address: "admin@mudcreek",
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
admin_user = User.find_by!(email_address: "admin@mudcreek")

lot_data = [
  { name: "Henderson Estate",    number: "001" },
  { name: "Blackwood Collection", number: "002" },
  { name: "Greenfield Manor",    number: "003" },
  { name: "Chapman Farm",        number: "004" },
  { name: "Personal Items",      number: "005" }
]

lots = lot_data.each_with_object({}) do |attrs, hash|
  hash[attrs[:name]] = Lot.find_or_create_by!(name: attrs[:name]) do |l|
    l.tenant = mudcreek
    l.number = attrs[:number]
    l.owner  = admin_user
  end
end

puts "Seeded #{Lot.count} lots."

listing_data = [
  # Furniture
  { name: "Victorian Parlour Chair",       price: 185,  pricing_type: :negotiable, description: "Beautifully carved walnut parlour chair with original needlepoint upholstery in a floral medallion pattern. Sturdy legs, minimal wear — a genuine Victorian-era piece from the Henderson drawing room.", published: true, physical: true },
  { name: "Oak Dining Table with Six Chairs", price: 450, description: "Solid quarter-sawn oak dining suite with a pedestal base and six matching ladder-back chairs with rush seats. Extends to seat ten. Light surface scratches only.", published: true, physical: true },
  { name: "Mahogany Dresser with Mirror",  price: 320,  pricing_type: :negotiable, description: "Seven-drawer mahogany dresser with a bevelled swivel mirror and original brass hardware. Dovetail joinery throughout. Excellent original finish with minor patina.", published: true, physical: true },
  { name: "Brass Bed Frame",              price: 275,  description: "Full-size ornate brass bed frame with original side rails. Thick tubing, solid castings, and fully functional. Includes slats. Circa 1910.", published: true, physical: true },
  { name: "Antique Writing Desk",         price: 385,  pricing_type: :negotiable, description: "Drop-front secretary desk in cherry with fitted interior — pigeon holes, small drawers, and a pull-out writing surface. Three lower drawers with original locks and skeleton keys.", published: true, physical: true },
  { name: "Windsor Chairs Set of Four",   price: 220,  pricing_type: :negotiable, description: "Matched set of four bow-back Windsor chairs in original black paint with gold pinstriping. Solid and sturdy with minor paint loss. Farm-fresh from the Chapman dining room.", published: true, physical: true },
  { name: "Cedar Chest",                  price: 165,  pricing_type: :negotiable, description: "Aromatic red cedar hope chest with tray insert and original hardware. Interior cedar is fragrant and unlined. Some light exterior scratches. Ideal for linens or blankets.", published: true, physical: true },
  { name: "Chesterfield Sofa",            price: 495,  pricing_type: :negotiable, description: "Classic rolled-arm Chesterfield in original burgundy leather with deep button tufting. Some patina on the armrests consistent with age. Extremely comfortable and structurally sound.", published: true, physical: true },
  { name: "Teak Garden Bench",            price: 140,  description: "Three-seat teak garden bench with slatted back and armrests. Silvered to a handsome grey with age. Hardware intact, no rot. Great outdoor piece.", published: true, physical: true },
  { name: "Rocking Chair",                price: 95,   pricing_type: :negotiable, description: "Pressed-back oak rocking chair with a carved floral crest rail and turned spindles. Original finish in good condition. Rockers show normal wear. Comfortable and solid.", published: true, physical: true },

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
  { name: "Cast Iron Bench Vise",         price: 95,   description: "Heavy 5\" jaw cast iron bench vise with swivel base and pipe jaws. Smooth action, no cracks or stripped threads. Mounts securely to a workbench.", published: true, physical: true },
  { name: "Crosscut Hand Saw",            price: 40,   description: "Disston No. 12 crosscut hand saw with a turned apple handle and 26\" blade. Teeth have been sharpened and set. Cuts cleanly. Medallion intact.", published: true },
  { name: "Vintage Level Set",            price: 35,   description: "Three vintage wood and brass spirit levels — 12\", 24\", and 36\" — all with readable bubbles. Some finish wear. Great for display or use.", published: true },

  # Books & Media
  { name: "Encyclopedia Britannica Set",  price: 95,   description: "Complete 1965 Encyclopedia Britannica in 24 volumes plus index. Burgundy cloth with gilt titles. All spines tight, pages clean. Includes original wooden bookends.", published: true, physical: true },
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
  { name: "Hand-hooked Wool Rug",         price: 195,  description: "Circa 1920 hand-hooked wool rug, 4' × 6', depicting a folk art floral wreath on a navy ground. Wool is dense and colours are vibrant. Bound edges intact.", published: true, physical: true },
  { name: "Framed Botanical Prints Set",  price: 85,   description: "Set of six antique hand-coloured botanical lithographs in matching mahogany frames. Circa 1870. Consistent minor foxing typical for age. Attractive grouping.", published: true },
  { name: "Bronze Horse Figurine",        price: 165,  description: "Solid bronze sculpture of a trotting horse on a marble plinth, signed 'Dubois' on the base. 8\" tall. Rich dark patina. No damage.", published: true },
  { name: "Tiffany-style Table Lamp",     price: 285,  pricing_type: :negotiable, description: "Leaded glass dragonfly shade on a cast metal base. 20\" shade diameter, overall height 26\". Wired and tested — all panels intact with no repairs.", published: true, physical: true },
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
  { name: "Cast Iron Garden Urns",        price: 165,  description: "Pair of matching cast iron garden urns on pedestal bases. Classical acanthus leaf design. Light surface rust — structurally sound. 18\" tall each.", published: true, physical: true },
  { name: "Antique Wheelbarrow",          price: 85,   pricing_type: :negotiable, description: "Vintage wooden wheelbarrow with iron wheel and banded hardwood tray. Painted red, well-worn. Functional and charming as a garden planter.", published: true, physical: true },
  { name: "Copper Garden Lanterns",       price: 95,   description: "Set of three wall-mount copper lanterns in graduated sizes. Aged verdigris patina. Glass panels intact. Wired for standard bulbs.", published: true, physical: true }
]

listing_data.each do |attrs|
  Listing.find_or_create_by!(name: attrs[:name]) do |l|
    l.tenant       = mudcreek
    l.price        = attrs[:price]
    l.pricing_type = attrs[:pricing_type] || :firm
    l.description  = attrs[:description]
    l.published    = attrs[:published]
    l.physical     = attrs[:physical] || false
    l.owner_id     = user_ids.sample
    l.state        = [ :sold, :on_sale ].sample
  end
end

puts "Seeded #{Listing.count} listings."

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
    "Framed Botanical Prints Set", "Gold Locket Necklace", "Pearl Bracelet"
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
    "Copper Cookware Set", "Cast Iron Dutch Oven", "Mink Stole", "Men's Tweed Hunting Jacket"
  ],
  "Chapman Farm" => [
    "Stanley Hand Plane Set", "Woodworking Chisel Set", "Cast Iron Bench Vise",
    "Crosscut Hand Saw", "Vintage Level Set", "Antique Wheelbarrow",
    "Encyclopedia Britannica Set", "Vinyl Record Collection", "First Edition Poetry Collection"
  ],
  "Personal Items" => [
    "Vintage Pyrex Mixing Bowl Set", "Beaded Evening Bag", "Vintage Hat Collection",
    "Vintage Tin Advertising Signs"
  ]
}

lot_assignments.each do |lot_name, listing_names|
  lot = lots[lot_name]
  next unless lot
  listing_names.each do |listing_name|
    Listing.where(name: listing_name).update_all(lot_id: lot.id)
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

categories = category_names.each_with_object({}) do |name, hash|
  hash[name] = Listings::Category.find_or_create_by!(name: name) do |c|
    c.tenant = mudcreek
  end
end

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
  "Copper Garden Lanterns"          => [ "Garden & Outdoor" ]
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

# Load a pool of stock images from fixtures, then assign one per listing.
FIXTURES_IMAGE_DIR = Rails.root.join("spec/fixtures/images")

stock_images = FIXTURES_IMAGE_DIR.glob("*.jpg").map do |path|
  { io: path.open("rb"), filename: path.basename.to_s, content_type: "image/jpeg" }
end

puts "Loaded #{stock_images.size} stock images from fixtures."

if stock_images.any?
  attached = 0
  Listing.find_each do |listing|
    next if listing.images.attached?
    img = stock_images.sample
    img[:io].rewind
    listing.images.attach(img)
    attached += 1
  end
  puts "Attached images to #{attached} listings."
end

# Offers
if Rails.env.development? || Rails.env.test?
  buyer_ids = User.where(tenant: mudcreek).where.not(email_address: "admin@mudcreek").pluck(:id)
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
    address: { street_address: "412 Elmwood Avenue", city: "Kamloops", province: "BC", postal_code: "V2C 1A1", country: "CA" },
    listings: [
      { name: "Victorian Parlour Chair",      starting_bid: 100, bid_increment: 10, reserve_price: 150 },
      { name: "Mahogany Dresser with Mirror", starting_bid: 200, bid_increment: 20, reserve_price: 280 },
      { name: "Clockwork Mantle Clock",       starting_bid: 100, bid_increment: 10, reserve_price: 175 },
      { name: "Crystal Decanter Set",         starting_bid:  50, bid_increment: 10, reserve_price: nil },
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
    address: { street_address: "88 Birchwood Court", city: "Revelstoke", province: "BC", postal_code: "V0E 2S0", country: "CA" },
    listings: [
      { name: "Gentleman's Pocket Watch",  starting_bid: 150, bid_increment: 25, reserve_price: 250 },
      { name: "Sterling Silver Cutlery Set", starting_bid: 150, bid_increment: 25, reserve_price: nil },
      { name: "Tiffany-style Table Lamp", starting_bid: 150, bid_increment: 25, reserve_price: 250 },
      { name: "Bronze Horse Figurine",     starting_bid:  75, bid_increment: 15, reserve_price: nil },
      { name: "Hand-hooked Wool Rug",      starting_bid: 100, bid_increment: 15, reserve_price: 165 }
    ]
  },
  {
    name: "Greenfield Manor Preview",
    starts_at: 3.weeks.from_now,
    ends_at: 5.weeks.from_now,
    published: false,
    reconciled: false,
    auto_approve: true,
    address: { street_address: "55 Manor Gate Road", city: "Penticton", province: "BC", postal_code: "V2A 1B3", country: "CA" },
    listings: [
      { name: "Vinyl Record Collection",        starting_bid: 40,  bid_increment: 5,  reserve_price: nil },
      { name: "Grundig Shortwave Radio",        starting_bid: 50,  bid_increment: 10, reserve_price: nil },
      { name: "Bakelite Table Radio",           starting_bid: 35,  bid_increment: 5,  reserve_price: nil },
      { name: "Oil Portrait",                   starting_bid: 100, bid_increment: 15, reserve_price: 175 }
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
    country: addr[:country]
  )

  attrs[:listings].each_with_index do |listing_attrs, idx|
    listing = Listing.find_by(name: listing_attrs[:name])
    next unless listing

    AuctionListing.create!(
      auction: auction,
      listing: listing,
      position: idx + 1,
      starting_bid_cents:  listing_attrs[:starting_bid]  ? listing_attrs[:starting_bid]  * 100 : nil,
      bid_increment_cents: listing_attrs[:bid_increment] ? listing_attrs[:bid_increment] * 100 : nil,
      reserve_price_cents: listing_attrs[:reserve_price] ? listing_attrs[:reserve_price] * 100 : nil
    )
  end

  auction
end

puts "Seeded #{Auction.count} auctions with #{AuctionListing.count} auction listings."

# Auction Registrations
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
  end
end
