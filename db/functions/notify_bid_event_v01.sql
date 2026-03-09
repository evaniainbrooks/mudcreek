CREATE OR REPLACE FUNCTION notify_bid_event()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify(
    'bid_events',
    json_build_object(
      'bid_id',                  NEW.id,
      'auction_listing_id',      NEW.auction_listing_id,
      'auction_registration_id', NEW.auction_registration_id,
      'amount_cents',            NEW.amount_cents,
      'state',                   NEW.state
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
