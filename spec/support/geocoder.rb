Geocoder.configure(lookup: :test)

Geocoder::Lookup::Test.set_default_stub(
  [
    {
      "coordinates"  => [50.6745, -120.3273],
      "address"      => "Kamloops, BC, Canada",
      "state"        => "British Columbia",
      "state_code"   => "BC",
      "country"      => "Canada",
      "country_code" => "CA"
    }
  ]
)
