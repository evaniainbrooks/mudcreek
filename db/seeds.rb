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

puts "Seeded #{Tenant.count} tenants."

# Backfill any existing records that predate the tenant column
[ Role, Permission, User, Listing, Listings::Category, CartItem ].each do |klass|
  count = klass.where(tenant_id: nil).update_all(tenant_id: mudcreek.id)
  puts "Backfilled #{count} #{klass.name} records to mudcreek tenant." if count > 0
end

# Roles & Permissions
all_resources = %w[Listing Lot User Role Permission Listings::Category Offer]
all_actions   = %w[index show create update destroy reorder]

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

admin_resources = %w[Listing]
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
  { name: "Gladmore Estate",  number: "001" },
  { name: "Westington Collection", number: "002" },
  { name: "Borneo Consignments",          number: "003" },
  { name: "Personal Items",        number: "004" },
  { name: "Huckleberry Collection",  number: "005" }
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
  # Cabins & Mountain Retreats
  { name: "Cozy Mountain Cabin", price: 285_000, pricing_type: :negotiable, description: "A charming log cabin nestled in the pines with breathtaking mountain views, a wrap-around porch, and a stone fireplace. Perfect as a weekend retreat or full-time residence.", published: true },
  { name: "Timber Frame Retreat", price: 445_000, pricing_type: :negotiable, description: "Handcrafted timber frame home deep in old-growth forest, with soaring ceilings, floor-to-ceiling windows, radiant heat, and a Finnish sauna.", published: true },
  { name: "Mountain Ski Chalet", price: 590_000, description: "Ski-in/ski-out chalet steps from the lifts with a heated mudroom, hot tub, stone fireplace, and sleeping for twelve. Strong short-term rental history.", published: true },
  { name: "Backcountry Retreat", price: 210_000, description: "Remote off-grid cabin accessible by ATV or snowmobile, surrounded by national forest. Solar power, propane appliances, and satellite internet.", published: false },
  { name: "Riverside Retreat", price: 175_000, pricing_type: :negotiable, description: "Secluded cabin along a quiet trout stream with excellent fishing, hiking trails, and wildlife viewing. Off-grid capable with solar panels and a well.", published: true },
  { name: "Alpine Lodge", price: 525_000, description: "Spacious alpine lodge with vaulted ceilings, exposed stone, a chef's kitchen, and wraparound deck with unobstructed mountain views at 8,000 ft elevation.", published: true },
  { name: "Bear Creek Cabin", price: 198_000, pricing_type: :negotiable, description: "Cozy two-bedroom cabin on 5 wooded acres along Bear Creek. Features a covered porch, wood stove, and direct access to backcountry hiking and fishing.", published: true },
  { name: "Pine Ridge Cabin", price: 235_000, pricing_type: :negotiable, description: "Well-maintained pine log cabin at the end of a quiet forest road. Three bedrooms, a large stone fireplace, and an outdoor hot tub with mountain views.", published: true },
  { name: "Cedar Bluff Retreat", price: 310_000, description: "Custom-built cedar cabin perched on a granite bluff with sweeping valley views. Open-concept living, radiant floor heat, and a two-car garage.", published: true },
  { name: "Spruce Haven Cabin", price: 175_000, pricing_type: :negotiable, description: "Snug four-season cabin tucked into a dense spruce forest. Recently renovated with a new metal roof, updated plumbing, and a screened porch.", published: true },
  { name: "Summit Ridge Chalet", price: 680_000, description: "Architect-designed mountain chalet with post-and-beam construction, floor-to-ceiling windows, a loft bedroom, and direct ski access from the back door.", published: true },
  { name: "Glacier View Lodge", price: 785_000, description: "Grand mountain lodge with six bedrooms, two great rooms, a commercial kitchen, and commanding views of a glacier-capped peak. Proven vacation rental income.", published: true },
  { name: "Aspen Grove Cabin", price: 260_000, pricing_type: :negotiable, description: "Charming cabin surrounded by golden aspens with a babbling brook, screened sleeping porch, and a detached bunkhouse for guests.", published: true },
  { name: "Hemlock Hollow Retreat", price: 195_000, pricing_type: :negotiable, description: "Private woodland retreat on 12 acres of old-growth hemlock. Simple but solid construction with a stone hearth, root cellar, and spring-fed water.", published: false },
  { name: "High Country Hunting Lodge", price: 890_000, description: "Purpose-built hunting lodge on 320 acres of prime elk and mule deer habitat. Includes a trophy room, walk-in cooler, equipment barn, and five en-suite bedrooms.", published: true },
  { name: "Snowshoe Cabin", price: 145_000, pricing_type: :negotiable, description: "Classic winter getaway cabin with easy snowshoe access, a wood-burning stove, loft sleeping, and a small ice fishing lake just steps away.", published: true },
  { name: "Ridgetop Retreat", price: 420_000, description: "Dramatic ridgetop home with 360-degree views, passive solar design, a rainwater collection system, and ten acres of private hillside terrain.", published: true },

  # Waterfront
  { name: "Lakefront Cottage", price: 420_000, pricing_type: :negotiable, description: "Peaceful waterfront property with a private dock, sandy beach, and stunning sunset views. Features an updated kitchen, three bedrooms, and a boathouse.", published: true },
  { name: "Fishing Camp", price: 225_000, description: "Rustic yet well-equipped fishing camp on a private lake with five sleeping cabins, a main lodge, boat storage, and a fish cleaning station.", published: true },
  { name: "Remote Island Cabin", price: 330_000, pricing_type: :negotiable, description: "Unique island property accessible only by boat or floatplane, with a well-built cabin, solar power, a dock, crab pots, and extraordinary solitude.", published: false },
  { name: "Lakeside Glamping Parcel", price: 260_000, description: "Established glamping business with four luxury canvas tent platforms, a bathhouse, fire pits, kayak storage, and direct lake access.", published: true },
  { name: "Sandy Cove Cottage", price: 385_000, pricing_type: :negotiable, description: "Adorable waterfront cottage with a private sandy cove, a floating dock, a screened sunroom, and a guest bunkie. Turnkey and fully furnished.", published: true },
  { name: "Dockside Retreat", price: 470_000, description: "Modern waterfront home with a deep-water dock, boathouse, outdoor kitchen, and an open-plan interior designed to maximize lake views from every room.", published: true },
  { name: "Bayfront Bungalow", price: 515_000, description: "Charming bungalow on a protected bay with calm, swimmable water, a long sandy beach, and a detached garage with a guest suite above.", published: true },
  { name: "River Bend Cabin", price: 215_000, pricing_type: :negotiable, description: "Secluded cabin on the inside of a gentle river bend with excellent fly fishing, a covered veranda over the water, and 8 acres of riparian land.", published: true },
  { name: "Lakeview Escape", price: 295_000, pricing_type: :negotiable, description: "Elevated property with panoramic lake views, a switchback trail to a private dock, a wraparound deck, and two sleeping lofts.", published: true },
  { name: "Marsh Landing Property", price: 340_000, description: "Unique tidal marsh property with a restored hunting cabin, a canoe launch, observation tower, and exceptional waterfowl habitat on 30 acres.", published: true },
  { name: "Peninsula Retreat", price: 625_000, description: "Rare peninsula property with water on three sides, a 200-ft shoreline, private boat launch, fire pit beach, and a beautifully renovated four-season cottage.", published: true },
  { name: "Inlet Hideaway", price: 190_000, pricing_type: :negotiable, description: "Rustic inlet property accessible by boat with a one-room cabin, a floating dock, an outhouse, and surrounded by old-growth coastal forest.", published: false },
  { name: "Waterfall Acreage", price: 280_000, pricing_type: :negotiable, description: "Stunning 22-acre property featuring a 40-foot seasonal waterfall, swimming hole, hiking trails, and a cleared building site with utilities nearby.", published: true },
  { name: "Tidal Creek Cottage", price: 360_000, description: "Low-country cottage on a navigable tidal creek with a covered porch, clam beds, kayak storage, and an outdoor shower. A coastal dream.", published: true },

  # Farms & Homesteads
  { name: "Rural Hobby Farm", price: 550_000, pricing_type: :negotiable, description: "15 acres of fertile land with a renovated farmhouse, two barns, a chicken coop, and fenced pastures. Ideal for small-scale agriculture or equestrian use.", published: true },
  { name: "Prairie Homestead", price: 390_000, description: "Classic farmhouse on 40 acres of open prairie with original hardwood floors, a modern kitchen, grain storage, and sweeping views in every direction.", published: true },
  { name: "Orchard Property", price: 310_000, description: "Productive apple and pear orchard with a restored farmhouse, cider barn, and roadside stand. A thriving agritourism operation with loyal local customers.", published: true },
  { name: "Valley View Farmhouse", price: 375_000, description: "Restored Victorian farmhouse with original millwork, updated plumbing and electrical, a large barn, and panoramic valley views from the covered porch.", published: true },
  { name: "River Bottom Farmland", price: 880_000, description: "Prime irrigated river bottom cropland in a productive agricultural valley. Class 1 soils, established water rights, and a large equipment shed.", published: true },
  { name: "Sunflower Homestead", price: 415_000, pricing_type: :negotiable, description: "Bright and welcoming 30-acre homestead with a renovated farmhouse, a large market garden, greenhouse, root cellar, and established orchard.", published: true },
  { name: "Rolling Hills Farm", price: 490_000, description: "Picturesque 75-acre farm rolling across gentle hills with a two-story farmhouse, dairy barn, equipment shed, and productive hayfields.", published: true },
  { name: "Heritage Grain Farm", price: 725_000, description: "Established 200-acre grain farm with Class 2 soils, a well-maintained farmhouse, three-phase power, grain bins, and a proven crop rotation history.", published: true },
  { name: "Blue Ridge Farmstead", price: 445_000, pricing_type: :negotiable, description: "Scenic mountain farmstead at 2,400 ft elevation with organic-certified pastures, a log home, spring-fed water, and a small flock of heritage sheep.", published: true },
  { name: "Clover Meadow Farm", price: 360_000, pricing_type: :negotiable, description: "Charming 20-acre farm with a restored 1890s farmhouse, a bank barn, herb garden, and fenced pastures currently supporting a small goat operation.", published: true },
  { name: "Harvest Moon Homestead", price: 530_000, description: "Self-sufficient 40-acre homestead with solar power, a wind turbine, a large root cellar, greenhouse, chicken house, and a cozy updated farmhouse.", published: true },
  { name: "Willow Creek Farm", price: 465_000, pricing_type: :negotiable, description: "Idyllic creek-side farm with a fieldstone farmhouse, a timber-frame barn, and 35 acres split between pasture, woodlot, and vegetable gardens.", published: true },
  { name: "Stone Wall Farm", price: 395_000, pricing_type: :negotiable, description: "Classic New England farm bounded by historic stone walls, with a cape-style farmhouse, sugar maple grove, two ponds, and 28 acres of mixed land.", published: true },
  { name: "Maple Sugar Farm", price: 480_000, description: "Working sugar bush with 3,000 taps, a modern sugarhouse, bottling facility, and retail shop. Includes a comfortable farmhouse and 60 acres of maple forest.", published: true },
  { name: "Lavender Field Farm", price: 340_000, pricing_type: :negotiable, description: "Aromatic 12-acre lavender farm with a distillery shed, farm store, wedding venue pavilion, and a charming Provençal-style farmhouse.", published: true },
  { name: "Blueberry Hill Farm", price: 285_000, pricing_type: :negotiable, description: "Established u-pick blueberry operation with 8 acres of mature bushes, a farm stand, irrigation system, and a three-bedroom farmhouse.", published: true },
  { name: "Bee Farm Homestead", price: 320_000, pricing_type: :negotiable, description: "Thriving honey operation with 80 active hives, a honey house, extraction equipment, retail storefront, and a restored farmhouse on 15 acres of clover.", published: true },
  { name: "Market Garden Property", price: 275_000, description: "Intensively managed 5-acre market garden with high tunnels, irrigation, walk-in cooler, and a small farmhouse. Supplies three local restaurants weekly.", published: true },
  { name: "Sheep Station Homestead", price: 610_000, description: "Complete sheep operation on 120 acres with a wool barn, shearing facility, lambing shed, a border collie kennel, and a handsome log farmhouse.", published: true },
  { name: "Dairy Farm Property", price: 950_000, description: "Fully operational small-scale dairy on 180 acres with a parlour barn, bulk tank, pasteurizer, licensed creamery, and a modern farmhouse.", published: true },

  # Ranches
  { name: "High Desert Ranch", price: 720_000, description: "200-acre high desert ranch with a modern hacienda-style home, working cattle operation, stock ponds, and outstanding mule deer hunting.", published: true },
  { name: "Working Cattle Ranch", price: 1_450_000, description: "Turnkey 500-acre cattle ranch with a fully updated ranch house, bunkhouse, multiple barns, corrals, a feedlot, and deeded water rights on a year-round creek.", published: true },
  { name: "Equestrian Estate", price: 980_000, description: "Premier equestrian property with a 12-stall barn, indoor arena, outdoor ring, 20 fenced acres of pasture, and a stunning 4-bedroom home.", published: true },
  { name: "Silver Creek Ranch", price: 825_000, description: "380-acre working ranch straddling Silver Creek with lush riparian meadows, hay production, a modern ranch house, and excellent elk hunting in the back country.", published: true },
  { name: "Eagle Ridge Ranch", price: 1_150_000, description: "Premier 600-acre cattle and horse ranch with a four-bedroom lodge, guest quarters, a 20-stall barn, indoor arena, and a private airstrip.", published: true },
  { name: "Prairie Wind Ranch", price: 675_000, description: "Open-range cattle ranch on 400 acres of native prairie grassland with a classic ranch house, working corrals, and strong lease income potential.", published: true },
  { name: "Big Sky Ranch", price: 1_080_000, description: "560-acre Montana-style ranch under a massive sky with a handsome log home, guest cabin, horse facilities, and a creek running through productive meadows.", published: true },
  { name: "Sagebrush Ranch", price: 590_000, pricing_type: :negotiable, description: "Classic high-desert ranch on 280 acres of open sagebrush rangeland with a solar-powered ranch house, stock wells, working corrals, and a calving barn.", published: true },
  { name: "Iron Horse Ranch", price: 765_000, description: "Well-established 320-acre horse property with a 16-stall barn, cross-country course, three-bedroom ranch home, and lush irrigated pastures.", published: true },
  { name: "Cottonwood Creek Ranch", price: 895_000, description: "Scenic 430-acre ranch along a cottonwood-lined creek with irrigated hay meadows, a remodeled ranch house, a bunkhouse, and outstanding fishing.", published: true },
  { name: "Thunder Ridge Ranch", price: 1_250_000, description: "Legacy 700-acre family ranch with a stunning log home, a guest lodge, working cattle facilities, private lake, and some of the best big-game hunting in the region.", published: true },

  # Land & Parcels
  { name: "Forested Acreage", price: 195_000, pricing_type: :negotiable, description: "60 acres of mixed hardwood forest with a small meadow clearing, seasonal creek, and a simple hunting cabin. Excellent timber value and wildlife habitat.", published: true },
  { name: "Coastal Bluff Lot", price: 490_000, description: "Rare buildable lot perched on a dramatic coastal bluff with unobstructed ocean views. Utilities at the road, approved for a 3,000 sq ft residence.", published: true },
  { name: "Wildflower Meadow Parcel", price: 130_000, pricing_type: :negotiable, description: "Beautiful 8-acre meadow parcel bordered by mature oaks, alive with native wildflowers in spring and summer. Ideal for a custom build or camping land.", published: true },
  { name: "Pine Timber Acreage", price: 220_000, pricing_type: :negotiable, description: "75 acres of mature plantation pine with a sustainable harvest plan, an established logging road network, and deeded access to a public boat launch.", published: true },
  { name: "Ridgeline Parcel", price: 155_000, pricing_type: :negotiable, description: "Dramatic 12-acre ridgeline parcel with cleared building sites, power at the road, and 180-degree views across a protected wilderness valley.", published: true },
  { name: "Valley Meadow Lot", price: 95_000, pricing_type: :negotiable, description: "Sunny 4-acre meadow lot in a productive farming valley with fertile soils, excellent sun exposure, a small pond, and paved road frontage.", published: true },
  { name: "Lakeside Buildable Lot", price: 185_000, description: "One of the last available lakefront lots in the area, with 120 ft of shoreline, a gentle slope to the water, and approved building plans available.", published: true },
  { name: "Hilltop View Parcel", price: 110_000, pricing_type: :negotiable, description: "Secluded 6-acre hilltop parcel with commanding 360-degree views, a drilled well, a septic perc test on file, and a roughed-in driveway.", published: true },
  { name: "Creek Bottom Acreage", price: 175_000, pricing_type: :negotiable, description: "Productive 30-acre creek bottom parcel with Class 1 soils, mature cottonwood riparian corridor, and established water rights perfect for irrigation.", published: true },
  { name: "Sunset Ridge Lot", price: 120_000, pricing_type: :negotiable, description: "South-facing 5-acre building lot with western exposure and spectacular sunset views. Includes a drilled well, electricity at the property line, and a gated entry.", published: true },
  { name: "Timberline Parcel", price: 245_000, pricing_type: :negotiable, description: "Pristine 40-acre parcel sitting right at the treeline on the south slope of a major peak. Mix of mature spruce forest and open alpine meadow.", published: false },
  { name: "Clifftop Lot", price: 380_000, description: "Exceptional half-acre clifftop building lot overlooking a river canyon. Engineered foundation plans in hand, power underground, and a gated private road.", published: true },
  { name: "Remote Forest Tract", price: 90_000, pricing_type: :negotiable, description: "100-acre remote forest tract accessible only by seasonal road. Rich wildlife habitat, trophy elk sign throughout, and complete privacy.", published: false },

  # Unique & Specialty
  { name: "Converted Barn Loft", price: 340_000, pricing_type: :negotiable, description: "One-of-a-kind converted dairy barn with soaring exposed timber ceilings, a chef's kitchen, two loft bedrooms, and a wraparound deck overlooking rolling hills.", published: true },
  { name: "Tiny House on Acreage", price: 165_000, pricing_type: :negotiable, description: "Thoughtfully designed 400 sq ft tiny house on 3 private acres with solar power, composting systems, a lush garden, and a workshop.", published: true },
  { name: "Woodland Artist Retreat", price: 295_000, pricing_type: :negotiable, description: "Quiet woodland property with a main cottage and a separate studio building flooded with north light. Surrounded by sculpture gardens and mature hardwoods.", published: true },
  { name: "Converted Silo Loft", price: 275_000, pricing_type: :negotiable, description: "Striking converted grain silo transformed into a two-story circular loft with custom curved windows, a rooftop deck, and a wrap-around garden.", published: true },
  { name: "Yurt on Acreage", price: 110_000, pricing_type: :negotiable, description: "Fully permitted 30-ft yurt on 5 private acres with a composting toilet, wood stove, solar array, and a lovely meadow setting near hiking trails.", published: true },
  { name: "Lighthouse Keeper's Cottage", price: 465_000, description: "Rare restored lighthouse property with a four-bedroom keeper's cottage, a functioning light tower, a private beach, and a registered heritage designation.", published: true },
  { name: "Old Schoolhouse Conversion", price: 290_000, pricing_type: :negotiable, description: "Lovingly converted one-room schoolhouse with original bell tower, wide-plank floors, exposed brick, an open-plan loft, and a half-acre in a charming village.", published: true },
  { name: "Church Conversion Loft", price: 320_000, pricing_type: :negotiable, description: "Dramatic conversion of a 1910 stone church into a two-level live-work loft. Soaring stained glass windows, original organ pipes, and a private walled courtyard.", published: true },
  { name: "Container Home Property", price: 240_000, pricing_type: :negotiable, description: "Modern off-grid compound built from four shipping containers on 8 acres, with a green roof, solar and wind power, a rainwater cistern, and orchard.", published: true },
  { name: "Treehouse Retreat", price: 185_000, pricing_type: :negotiable, description: "Professionally built treehouse retreat set 20 ft into a canopy of old-growth oaks. Two sleeping platforms, a suspended rope bridge, composting toilet, and solar.", published: true },
  { name: "Windmill Farm Estate", price: 615_000, description: "Historic windmill property on 25 acres with a restored Dutch-style windmill (currently producing flour), a four-bedroom farmhouse, and a small farm store.", published: true },
  { name: "Underground Earth Shelter", price: 195_000, pricing_type: :negotiable, description: "Ingeniously built earth-sheltered home bermed into a south-facing hillside with passive solar gain, exceptional insulation, and a rooftop wildflower meadow.", published: false },

  # Desert & Southwest
  { name: "Desert Adobe Estate", price: 620_000, description: "Stunning Southwest-style home with exposed vigas, terracotta tile floors, a courtyard pool, and panoramic desert and mountain views on 5 acres.", published: true },
  { name: "Red Rock Canyon Estate", price: 780_000, description: "Dramatic red-rock country estate surrounded by towering sandstone formations, with a Santa Fe-style home, infinity pool, artist studio, and 12 acres of privacy.", published: true },
  { name: "Saguaro Flats Ranch", price: 490_000, description: "Authentic desert ranch on 160 acres of saguaro-studded bajada, with a Territorial-style home, a guest casita, stock tank, and working cattle pens.", published: true },
  { name: "Mesa Verde Retreat", price: 545_000, description: "Mesa-top retreat with commanding views of multiple mountain ranges, a passive-solar adobe home, a water storage cistern, and 20 acres of high desert terrain.", published: true },
  { name: "Canyon Rim Property", price: 415_000, pricing_type: :negotiable, description: "Breathtaking canyon rim property with a 500-ft sheer drop to the river below, a custom timber home, a fire lookout tower conversion, and 15 acres.", published: true },
  { name: "Desert Blossom Homestead", price: 355_000, pricing_type: :negotiable, description: "Lush desert homestead with a walled courtyard garden, acequia water rights, a ramada, fruit trees, raised beds, and an adobe farmhouse.", published: true },
  { name: "Pinon Hills Cabin", price: 210_000, pricing_type: :negotiable, description: "Comfortable cabin in the piñon-juniper highlands with a kiva fireplace, Saltillo tile floors, a covered portal, and 3 acres of high-desert serenity.", published: true },
  { name: "Joshua Tree Retreat", price: 335_000, pricing_type: :negotiable, description: "Architect-designed desert retreat among ancient Joshua trees, featuring a passive-solar layout, polished concrete floors, an outdoor soaking tub, and five acres.", published: true },

  # Recreation & Glamping
  { name: "Off-Grid Solar Homestead", price: 285_000, pricing_type: :negotiable, description: "Fully off-grid homestead with a 10kW solar array, battery bank, propane backup, well and septic, a 2,000 sq ft timber-frame home, and a productive garden.", published: true },
  { name: "Hunting Lodge Compound", price: 1_100_000, description: "Premier hunting compound on 900 acres of private wilderness with a 10-bedroom lodge, guides' quarters, equipment barn, walk-in cooler, and airstrip.", published: true },
  { name: "RV Resort Property", price: 750_000, description: "Established 40-site RV resort on 15 acres with full hookups, a bathhouse, camp store, playground, fire pits, and a strong occupancy track record.", published: true },
  { name: "Campground Business", price: 620_000, description: "Operating campground with 60 sites (tents and RVs), 6 glamping cabins, a swimming hole, a general store, and loyal repeat customers.", published: true },
  { name: "Duck Hunting Marsh", price: 320_000, pricing_type: :negotiable, description: "Prime 200-acre waterfowl marsh with a fully equipped hunt camp, pit blinds, water control structures, and an outstanding history of public wing shooting.", published: true },

  # Vineyards & Orchards
  { name: "Vineyard Parcel", price: 875_000, description: "Established vineyard with 8 acres of Pinot Noir and Chardonnay vines, a production winery, tasting room, and farmhouse. Turnkey wine country operation.", published: true },
  { name: "Vineyard Estate", price: 1_350_000, description: "Prestigious wine country estate with 22 acres of producing vines, a gravity-flow winery, a tasting pavilion, a five-bedroom manor home, and a guest cottage.", published: true },
  { name: "Apple Hill Orchard", price: 425_000, pricing_type: :negotiable, description: "Thriving 18-acre apple operation with 15 heritage varieties, a licensed cidery, farm market, pick-your-own revenue, and a comfortable farmhouse.", published: true },
  { name: "Cherry Farm", price: 385_000, pricing_type: :negotiable, description: "Productive cherry farm with 600 mature sweet and sour trees, a mechanical harvester, cold storage, direct-to-grocery contracts, and a farmhouse.", published: true },
]

listing_data.each do |attrs|
  Listing.find_or_create_by!(name: attrs[:name]) do |l|
    l.tenant = mudcreek
    l.price = attrs[:price]
    l.pricing_type = attrs[:pricing_type] || :firm
    l.description = attrs[:description]
    l.published = attrs[:published]
    l.owner_id = user_ids.sample
    l.state = [:sold, :on_sale].sample
  end
end

puts "Seeded #{Listing.count} listings."

# Assign listings to lots
lot_assignments = {
  "Gladmore Estate" => [
    "Cozy Mountain Cabin", "Timber Frame Retreat", "Mountain Ski Chalet", "Backcountry Retreat",
    "Riverside Retreat", "Alpine Lodge", "Bear Creek Cabin", "Pine Ridge Cabin",
    "Cedar Bluff Retreat", "Spruce Haven Cabin", "Summit Ridge Chalet", "Glacier View Lodge",
    "Aspen Grove Cabin", "Hemlock Hollow Retreat", "High Country Hunting Lodge",
    "Snowshoe Cabin", "Ridgetop Retreat"
  ],
  "Westington Collection" => [
    "Lakefront Cottage", "Fishing Camp", "Remote Island Cabin", "Lakeside Glamping Parcel",
    "Sandy Cove Cottage", "Dockside Retreat", "Bayfront Bungalow", "River Bend Cabin",
    "Lakeview Escape", "Marsh Landing Property", "Peninsula Retreat", "Inlet Hideaway",
    "Waterfall Acreage", "Tidal Creek Cottage"
  ],
  "Borneo Consignments" => [
    "Rural Hobby Farm", "Prairie Homestead", "Orchard Property", "River Bottom Farmland",
    "Working Cattle Ranch", "Valley View Farmhouse", "Equestrian Estate", "Sunflower Homestead",
    "Rolling Hills Farm", "Heritage Grain Farm", "Blue Ridge Farmstead", "Clover Meadow Farm",
    "Harvest Moon Homestead", "Willow Creek Farm", "Stone Wall Farm", "Maple Sugar Farm",
    "Lavender Field Farm", "Blueberry Hill Farm", "Bee Farm Homestead", "Market Garden Property",
    "Sheep Station Homestead", "Dairy Farm Property",
    "High Desert Ranch", "Silver Creek Ranch", "Eagle Ridge Ranch", "Prairie Wind Ranch",
    "Big Sky Ranch", "Sagebrush Ranch", "Iron Horse Ranch", "Cottonwood Creek Ranch",
    "Thunder Ridge Ranch", "Vineyard Parcel", "Vineyard Estate", "Apple Hill Orchard", "Cherry Farm"
  ],
  "Personal Items" => [
    "Forested Acreage", "Coastal Bluff Lot", "Wildflower Meadow Parcel", "Pine Timber Acreage",
    "Ridgeline Parcel", "Valley Meadow Lot", "Lakeside Buildable Lot", "Hilltop View Parcel",
    "Creek Bottom Acreage", "Sunset Ridge Lot", "Timberline Parcel", "Clifftop Lot",
    "Remote Forest Tract"
  ],
  "Huckleberry Collection" => [
    "Desert Adobe Estate", "Converted Barn Loft", "Tiny House on Acreage", "Woodland Artist Retreat",
    "Converted Silo Loft", "Yurt on Acreage", "Lighthouse Keeper's Cottage", "Old Schoolhouse Conversion",
    "Church Conversion Loft", "Container Home Property", "Treehouse Retreat", "Windmill Farm Estate",
    "Underground Earth Shelter", "Red Rock Canyon Estate", "Saguaro Flats Ranch", "Mesa Verde Retreat",
    "Canyon Rim Property", "Desert Blossom Homestead", "Pinon Hills Cabin", "Joshua Tree Retreat",
    "Off-Grid Solar Homestead", "Hunting Lodge Compound", "RV Resort Property", "Campground Business",
    "Duck Hunting Marsh"
  ]
}

lot_assignments.each do |lot_name, listing_names|
  lot = lots[lot_name]
  listing_names.each do |listing_name|
    Listing.where(name: listing_name).update_all(lot_id: lot.id) if lot
  end
end

# Listing Categories
category_names = [
  "Cabins & Retreats",
  "Farms & Homesteads",
  "Ranches",
  "Land & Parcels",
  "Equestrian",
  "Vineyards & Orchards",
  "Recreation & Glamping",
  "Unique Properties"
]

categories = category_names.each_with_object({}) do |name, hash|
  hash[name] = Listings::Category.find_or_create_by!(name: name) do |c|
    c.tenant = mudcreek
  end
end

category_assignments = {
  # Cabins & Retreats
  "Cozy Mountain Cabin"          => [ "Cabins & Retreats" ],
  "Timber Frame Retreat"         => [ "Cabins & Retreats", "Unique Properties" ],
  "Mountain Ski Chalet"          => [ "Cabins & Retreats", "Recreation & Glamping" ],
  "Backcountry Retreat"          => [ "Cabins & Retreats" ],
  "Riverside Retreat"            => [ "Cabins & Retreats", "Recreation & Glamping" ],
  "Alpine Lodge"                 => [ "Cabins & Retreats" ],
  "Bear Creek Cabin"             => [ "Cabins & Retreats" ],
  "Pine Ridge Cabin"             => [ "Cabins & Retreats" ],
  "Cedar Bluff Retreat"          => [ "Cabins & Retreats" ],
  "Spruce Haven Cabin"           => [ "Cabins & Retreats" ],
  "Summit Ridge Chalet"          => [ "Cabins & Retreats", "Unique Properties" ],
  "Glacier View Lodge"           => [ "Cabins & Retreats", "Recreation & Glamping" ],
  "Aspen Grove Cabin"            => [ "Cabins & Retreats" ],
  "Hemlock Hollow Retreat"       => [ "Cabins & Retreats" ],
  "High Country Hunting Lodge"   => [ "Cabins & Retreats", "Recreation & Glamping" ],
  "Snowshoe Cabin"               => [ "Cabins & Retreats" ],
  "Ridgetop Retreat"             => [ "Cabins & Retreats", "Unique Properties" ],
  "Remote Island Cabin"          => [ "Cabins & Retreats", "Unique Properties" ],
  "Fishing Camp"                 => [ "Cabins & Retreats", "Recreation & Glamping" ],
  # Waterfront / Recreation
  "Lakefront Cottage"            => [ "Cabins & Retreats", "Recreation & Glamping" ],
  "Lakeside Glamping Parcel"     => [ "Recreation & Glamping" ],
  "Sandy Cove Cottage"           => [ "Cabins & Retreats" ],
  "Dockside Retreat"             => [ "Cabins & Retreats" ],
  "Bayfront Bungalow"            => [ "Cabins & Retreats" ],
  "River Bend Cabin"             => [ "Cabins & Retreats" ],
  "Lakeview Escape"              => [ "Cabins & Retreats" ],
  "Marsh Landing Property"       => [ "Recreation & Glamping" ],
  "Peninsula Retreat"            => [ "Cabins & Retreats", "Recreation & Glamping" ],
  "Inlet Hideaway"               => [ "Cabins & Retreats" ],
  "Waterfall Acreage"            => [ "Land & Parcels" ],
  "Tidal Creek Cottage"          => [ "Cabins & Retreats" ],
  # Farms & Homesteads
  "Rural Hobby Farm"             => [ "Farms & Homesteads" ],
  "Prairie Homestead"            => [ "Farms & Homesteads" ],
  "Valley View Farmhouse"        => [ "Farms & Homesteads" ],
  "River Bottom Farmland"        => [ "Farms & Homesteads", "Land & Parcels" ],
  "Sunflower Homestead"          => [ "Farms & Homesteads" ],
  "Rolling Hills Farm"           => [ "Farms & Homesteads" ],
  "Heritage Grain Farm"          => [ "Farms & Homesteads" ],
  "Blue Ridge Farmstead"         => [ "Farms & Homesteads" ],
  "Clover Meadow Farm"           => [ "Farms & Homesteads" ],
  "Harvest Moon Homestead"       => [ "Farms & Homesteads", "Unique Properties" ],
  "Willow Creek Farm"            => [ "Farms & Homesteads" ],
  "Stone Wall Farm"              => [ "Farms & Homesteads" ],
  "Maple Sugar Farm"             => [ "Farms & Homesteads", "Vineyards & Orchards" ],
  "Lavender Field Farm"          => [ "Farms & Homesteads", "Unique Properties" ],
  "Blueberry Hill Farm"          => [ "Farms & Homesteads", "Vineyards & Orchards" ],
  "Bee Farm Homestead"           => [ "Farms & Homesteads" ],
  "Market Garden Property"       => [ "Farms & Homesteads" ],
  "Sheep Station Homestead"      => [ "Farms & Homesteads" ],
  "Dairy Farm Property"          => [ "Farms & Homesteads" ],
  "Orchard Property"             => [ "Vineyards & Orchards", "Farms & Homesteads" ],
  # Ranches
  "High Desert Ranch"            => [ "Ranches" ],
  "Working Cattle Ranch"         => [ "Ranches", "Farms & Homesteads" ],
  "Equestrian Estate"            => [ "Equestrian" ],
  "Silver Creek Ranch"           => [ "Ranches" ],
  "Eagle Ridge Ranch"            => [ "Ranches", "Equestrian" ],
  "Prairie Wind Ranch"           => [ "Ranches" ],
  "Big Sky Ranch"                => [ "Ranches" ],
  "Sagebrush Ranch"              => [ "Ranches" ],
  "Iron Horse Ranch"             => [ "Ranches", "Equestrian" ],
  "Cottonwood Creek Ranch"       => [ "Ranches" ],
  "Thunder Ridge Ranch"          => [ "Ranches", "Recreation & Glamping" ],
  "Saguaro Flats Ranch"          => [ "Ranches" ],
  # Land & Parcels
  "Forested Acreage"             => [ "Land & Parcels" ],
  "Coastal Bluff Lot"            => [ "Land & Parcels" ],
  "Wildflower Meadow Parcel"     => [ "Land & Parcels" ],
  "Pine Timber Acreage"          => [ "Land & Parcels" ],
  "Ridgeline Parcel"             => [ "Land & Parcels" ],
  "Valley Meadow Lot"            => [ "Land & Parcels", "Farms & Homesteads" ],
  "Lakeside Buildable Lot"       => [ "Land & Parcels" ],
  "Hilltop View Parcel"          => [ "Land & Parcels" ],
  "Creek Bottom Acreage"         => [ "Land & Parcels" ],
  "Sunset Ridge Lot"             => [ "Land & Parcels" ],
  "Timberline Parcel"            => [ "Land & Parcels" ],
  "Clifftop Lot"                 => [ "Land & Parcels" ],
  "Remote Forest Tract"          => [ "Land & Parcels" ],
  # Unique Properties
  "Converted Barn Loft"          => [ "Unique Properties" ],
  "Tiny House on Acreage"        => [ "Unique Properties" ],
  "Woodland Artist Retreat"      => [ "Unique Properties" ],
  "Converted Silo Loft"          => [ "Unique Properties" ],
  "Yurt on Acreage"              => [ "Unique Properties", "Recreation & Glamping" ],
  "Lighthouse Keeper's Cottage"  => [ "Unique Properties", "Cabins & Retreats" ],
  "Old Schoolhouse Conversion"   => [ "Unique Properties" ],
  "Church Conversion Loft"       => [ "Unique Properties" ],
  "Container Home Property"      => [ "Unique Properties" ],
  "Treehouse Retreat"            => [ "Unique Properties", "Cabins & Retreats" ],
  "Windmill Farm Estate"         => [ "Unique Properties", "Farms & Homesteads" ],
  "Underground Earth Shelter"    => [ "Unique Properties" ],
  # Desert & Southwest
  "Desert Adobe Estate"          => [ "Unique Properties" ],
  "Red Rock Canyon Estate"       => [ "Unique Properties" ],
  "Mesa Verde Retreat"           => [ "Unique Properties", "Cabins & Retreats" ],
  "Canyon Rim Property"          => [ "Unique Properties", "Land & Parcels" ],
  "Desert Blossom Homestead"     => [ "Farms & Homesteads", "Unique Properties" ],
  "Pinon Hills Cabin"            => [ "Cabins & Retreats" ],
  "Joshua Tree Retreat"          => [ "Cabins & Retreats", "Unique Properties" ],
  # Recreation
  "Off-Grid Solar Homestead"     => [ "Unique Properties", "Farms & Homesteads" ],
  "Hunting Lodge Compound"       => [ "Recreation & Glamping", "Cabins & Retreats" ],
  "RV Resort Property"           => [ "Recreation & Glamping" ],
  "Campground Business"          => [ "Recreation & Glamping" ],
  "Duck Hunting Marsh"           => [ "Recreation & Glamping" ],
  # Vineyards & Orchards
  "Vineyard Parcel"              => [ "Vineyards & Orchards" ],
  "Vineyard Estate"              => [ "Vineyards & Orchards" ],
  "Apple Hill Orchard"           => [ "Vineyards & Orchards", "Farms & Homesteads" ],
  "Cherry Farm"                  => [ "Vineyards & Orchards", "Farms & Homesteads" ],
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
    # Cozy Mountain Cabin — one accepted (listing goes sold), two declined
    { listing: "Cozy Mountain Cabin", amount: 265_000, message: "Love the location, would you take a bit less?", state: :declined },
    { listing: "Cozy Mountain Cabin", amount: 270_000, message: "Cash buyer, can close quickly.", state: :declined },
    { listing: "Cozy Mountain Cabin", amount: 278_000, message: "Final offer, very motivated buyer.", state: :accepted },

    # Lakefront Cottage — two pending
    { listing: "Lakefront Cottage", amount: 395_000, message: "Interested in the property, willing to negotiate.", state: :pending },
    { listing: "Lakefront Cottage", amount: 400_000, message: nil, state: :pending },

    # Rural Hobby Farm — one declined, one pending
    { listing: "Rural Hobby Farm", amount: 510_000, message: "Farm has been in our sights for months.", state: :declined },
    { listing: "Rural Hobby Farm", amount: 530_000, message: "Ready to move forward if price works.", state: :pending },

    # Riverside Retreat — one accepted (listing goes sold)
    { listing: "Riverside Retreat", amount: 168_000, message: "Perfect fishing spot, would love to own it.", state: :accepted },

    # Forested Acreage — pending only
    { listing: "Forested Acreage", amount: 180_000, message: "Timber rights included?", state: :pending },

    # Timber Frame Retreat — one declined, one pending
    { listing: "Timber Frame Retreat", amount: 410_000, message: nil, state: :declined },
    { listing: "Timber Frame Retreat", amount: 430_000, message: "Absolutely stunning build, making my best offer.", state: :pending },

    # Converted Barn Loft — pending
    { listing: "Converted Barn Loft", amount: 320_000, message: "Unique property, flexible on closing date.", state: :pending },

    # Tiny House on Acreage — pending
    { listing: "Tiny House on Acreage", amount: 155_000, message: "Minimalist lifestyle is exactly what we want.", state: :pending },

    # Woodland Artist Retreat — one declined
    { listing: "Woodland Artist Retreat", amount: 275_000, message: "Looking for a quiet creative space.", state: :declined },
    { listing: "Woodland Artist Retreat", amount: 285_000, message: nil, state: :pending }
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
  { key: "WELCOME10",  discount_type: :fixed,      amount_cents:  1_000, start_at: nil,           end_at: nil },
  { key: "SAVE50",     discount_type: :fixed,      amount_cents:  5_000, start_at: nil,           end_at: nil },
  { key: "SUMMER25",   discount_type: :percentage, amount_cents:  2_500, start_at: nil,           end_at: 1.month.from_now },
  { key: "FALL15",     discount_type: :percentage, amount_cents:  1_500, start_at: nil,           end_at: nil },
  { key: "EARLYBIRD",  discount_type: :fixed,      amount_cents: 25_000, start_at: nil,           end_at: 2.weeks.from_now },
  { key: "EXPIRED20",  discount_type: :percentage, amount_cents:  2_000, start_at: 3.months.ago,  end_at: 1.month.ago },
  { key: "FUTURE100",  discount_type: :fixed,      amount_cents: 10_000, start_at: 1.month.from_now, end_at: 2.months.from_now }
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
