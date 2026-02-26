default_password = Rails.application.credentials.seeds.default_user_password

# Roles & Permissions
all_resources = %w[Listing User Role Permission]
all_actions   = %w[index show create update destroy]

super_admin = Role.find_or_create_by!(name: "super_admin") do |r|
  r.description = "Full access to everything."
end

admin = Role.find_or_create_by!(name: "admin") do |r|
  r.description = "Full access to listings. No access to users or roles."
end

Role.find_or_create_by!(name: "user") do |r|
  r.description = "Standard user with no admin permissions."
end

all_resources.each do |resource|
  all_actions.each do |action|
    super_admin.permissions.find_or_create_by!(resource: resource, action: action)
  end
end

admin_resources = %w[Listing]
admin_resources.each do |resource|
  all_actions.each do |action|
    admin.permissions.find_or_create_by!(resource: resource, action: action)
  end
end

puts "Seeded #{Role.count} roles and #{Permission.count} permissions."

User.find_or_create_by!(email_address: "admin@mudcreek") do |u|
  u.password = default_password
  u.password_confirmation = default_password
  u.role = super_admin
end

# Generate fake users for dev pagination testing
if Rails.env.development? || Rails.env.test?
  require "faker"
  60.times do
    User.find_or_create_by!(email_address: Faker::Internet.unique.email) do |u|
      password = Faker::Internet.password
      u.password = password
      u.password_confirmation = password
    end
  end
end

puts "Seeded #{User.count} users."

user_ids = User.pluck(:id)

listing_data = [
  { name: "Cozy Mountain Cabin", price: 285_000, description: "A charming log cabin nestled in the pines with breathtaking mountain views, a wrap-around porch, and a stone fireplace. Perfect as a weekend retreat or full-time residence.", published: true },
  { name: "Lakefront Cottage", price: 420_000, description: "Peaceful waterfront property with a private dock, sandy beach, and stunning sunset views. Features an updated kitchen, three bedrooms, and a boathouse.", published: true },
  { name: "Rural Hobby Farm", price: 550_000, description: "15 acres of fertile land with a renovated farmhouse, two barns, a chicken coop, and fenced pastures. Ideal for small-scale agriculture or equestrian use.", published: true },
  { name: "Riverside Retreat", price: 175_000, description: "Secluded cabin along a quiet trout stream with excellent fishing, hiking trails, and wildlife viewing. Off-grid capable with solar panels and a well.", published: true },
  { name: "Prairie Homestead", price: 390_000, description: "Classic farmhouse on 40 acres of open prairie with original hardwood floors, a modern kitchen, grain storage, and sweeping views in every direction.", published: true },
  { name: "Desert Adobe Estate", price: 620_000, description: "Stunning Southwest-style home with exposed vigas, terracotta tile floors, a courtyard pool, and panoramic desert and mountain views on 5 acres.", published: true },
  { name: "Orchard Property", price: 310_000, description: "Productive apple and pear orchard with a restored farmhouse, cider barn, and roadside stand. A thriving agritourism operation with loyal local customers.", published: true },
  { name: "Forested Acreage", price: 195_000, description: "60 acres of mixed hardwood forest with a small meadow clearing, seasonal creek, and a simple hunting cabin. Excellent timber value and wildlife habitat.", published: true },
  { name: "Vineyard Parcel", price: 875_000, description: "Established vineyard with 8 acres of Pinot Noir and Chardonnay vines, a production winery, tasting room, and farmhouse. Turnkey wine country operation.", published: true },
  { name: "Coastal Bluff Lot", price: 490_000, description: "Rare buildable lot perched on a dramatic coastal bluff with unobstructed ocean views. Utilities at the road, approved for a 3,000 sq ft residence.", published: true },
  { name: "Timber Frame Retreat", price: 445_000, description: "Handcrafted timber frame home deep in old-growth forest, with soaring ceilings, floor-to-ceiling windows, radiant heat, and a Finnish sauna.", published: true },
  { name: "High Desert Ranch", price: 720_000, description: "200-acre high desert ranch with a modern hacienda-style home, working cattle operation, stock ponds, and outstanding mule deer hunting.", published: true },
  { name: "Wildflower Meadow Parcel", price: 130_000, description: "Beautiful 8-acre meadow parcel bordered by mature oaks, alive with native wildflowers in spring and summer. Ideal for a custom build or camping land.", published: true },
  { name: "Converted Barn Loft", price: 340_000, description: "One-of-a-kind converted dairy barn with soaring exposed timber ceilings, a chef's kitchen, two loft bedrooms, and a wraparound deck overlooking rolling hills.", published: true },
  { name: "Fishing Camp", price: 225_000, description: "Rustic yet well-equipped fishing camp on a private lake with five sleeping cabins, a main lodge, boat storage, and a fish cleaning station.", published: true },
  { name: "Mountain Ski Chalet", price: 590_000, description: "Ski-in/ski-out chalet steps from the lifts with a heated mudroom, hot tub, stone fireplace, and sleeping for twelve. Strong short-term rental history.", published: true },
  { name: "River Bottom Farmland", price: 880_000, description: "Prime irrigated river bottom cropland in a productive agricultural valley. Class 1 soils, established water rights, and a large equipment shed.", published: true },
  { name: "Tiny House on Acreage", price: 165_000, description: "Thoughtfully designed 400 sq ft tiny house on 3 private acres with solar power, composting systems, a lush garden, and a workshop.", published: true },
  { name: "Lakeside Glamping Parcel", price: 260_000, description: "Established glamping business with four luxury canvas tent platforms, a bathhouse, fire pits, kayak storage, and direct lake access.", published: true },
  { name: "Working Cattle Ranch", price: 1_450_000, description: "Turnkey 500-acre cattle ranch with a fully updated ranch house, bunkhouse, multiple barns, corrals, a feedlot, and deeded water rights on a year-round creek.", published: true },
  { name: "Backcountry Retreat", price: 210_000, description: "Remote off-grid cabin accessible by ATV or snowmobile, surrounded by national forest. Solar power, propane appliances, and satellite internet.", published: false },
  { name: "Valley View Farmhouse", price: 375_000, description: "Restored Victorian farmhouse with original millwork, updated plumbing and electrical, a large barn, and panoramic valley views from the covered porch.", published: true },
  { name: "Woodland Artist Retreat", price: 295_000, description: "Quiet woodland property with a main cottage and a separate studio building flooded with north light. Surrounded by sculpture gardens and mature hardwoods.", published: true },
  { name: "Equestrian Estate", price: 980_000, description: "Premier equestrian property with a 12-stall barn, indoor arena, outdoor ring, 20 fenced acres of pasture, and a stunning 4-bedroom home.", published: true },
  { name: "Remote Island Cabin", price: 330_000, description: "Unique island property accessible only by boat or floatplane, with a well-built cabin, solar power, a dock, crab pots, and extraordinary solitude.", published: false }
]

listing_data.each do |attrs|
  Listing.find_or_create_by!(name: attrs[:name]) do |l|
    l.price = attrs[:price]
    l.description = attrs[:description]
    l.published = attrs[:published]
    l.owner_id = user_ids.sample
  end
end

puts "Seeded #{Listing.count} listings."

require "open-uri"

# Download a pool of stock images from Picsum Photos, then assign one per listing.
PICSUM_SEEDS = %w[mountain lake farm river prairie desert orchard forest vineyard coast timber ranch meadow barn fishing]

puts "Downloading #{PICSUM_SEEDS.size} stock images..."

stock_images = PICSUM_SEEDS.filter_map do |seed|
  print "  #{seed}... "
  io = URI.open("https://picsum.photos/seed/#{seed}/800/600")
  puts "done"
  { io: io, filename: "#{seed}.jpg", content_type: "image/jpeg" }
rescue => e
  puts "failed (#{e.message})"
  nil
end

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
