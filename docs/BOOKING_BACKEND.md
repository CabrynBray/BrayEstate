# Production booking backend checklist (GitHub Pages + Supabase + Stripe)

## Recommended stack
- Static pages: GitHub Pages.
- Database and server-side API: Supabase Postgres + Supabase Edge Functions.
- Checkout: Stripe Checkout.
- Email: Resend or Postmark.
- Optional scheduled cleanup: Supabase scheduled function/cron to expire abandoned holds.

## Request flow
1. Browser sends only the chosen booking type, package ID, inventory IDs, dates/times, guest count, contact details, and add-on IDs.
2. Edge Function validates fields and property rules; calculates prices from database records; checks blocks and active reservations.
3. In one database transaction, create a pending booking and short-lived reservation rows. The `inventory_reservations` exclusion constraint is the final double-booking guard.
4. Create a Stripe Checkout Session with the booking ID in metadata and the server-calculated amount. Use an idempotency key.
5. Return only the hosted `checkoutUrl` to the browser.
6. Stripe calls a public webhook endpoint. Verify the signature using the raw request body and `STRIPE_WEBHOOK_SECRET`.
7. On a verified successful payment event, mark booking and reservations `confirmed`, save Stripe IDs, and send confirmation email. Record Stripe event IDs to make webhook handling idempotent.
8. If checkout expires or payment fails, mark the booking/reservations expired and release the inventory.
9. On the success page, show a booking reference only; fetch authoritative confirmation status from the backend if needed. The page itself is not proof of payment.

## Suggested Edge Functions
- `availability`: returns bookable date/time options and public package/rate labels.
- `create-checkout-session`: validates selection, creates hold, creates Stripe session.
- `stripe-webhook`: verifies Stripe signature and finalizes payment.
- `booking-status`: returns a minimal status for a public reference without exposing guest data.
- `expire-holds`: scheduled cleanup of stale holds.

## Availability rules to encode
- One reservation per inventory unit for overlapping occupied time ranges.
- Accommodation ranges are `[local check-in, local checkout)`. Include cleaning buffer only if it truly prevents same-day turnover.
- Event ranges include required setup/teardown buffers.
- Optional estate-wide exclusivity: add an `estate` inventory item and reserve it for packages that require the entire property.
- If multiple event areas can run independently, model each as separate inventory. Do not allow overlap on a shared resource such as parking or the entire estate unless capacity and operations allow it.
- A combined booking creates multiple reservations atomically; if any item is unavailable, roll back the entire booking.
- Hold expiration is short (start with 10–15 minutes, then test conversion rates and operational needs).
- Availability shown in the browser is advisory; revalidate at checkout creation.
- Confirm only from a verified Stripe webhook, never from a query parameter or redirect alone.

## Stripe configuration
1. Create Stripe account and configure business details, payout bank, statement descriptor, and refund policy.
2. Create test-mode products/prices only if using Stripe Price IDs; otherwise create Checkout Sessions with server-calculated `price_data`.
3. Add `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `SUPABASE_URL`, and server-only Supabase service-role credentials as Edge Function secrets. Never put these in `assets/main.js`, HTML, GitHub, or browser-visible environment variables.
4. Configure Checkout success/cancel URLs to the GitHub Pages pages. Example:
   - `https://YOUR-USERNAME.github.io/bray-estate/booking-success.html?session_id={CHECKOUT_SESSION_ID}`
   - `https://YOUR-USERNAME.github.io/bray-estate/booking-cancelled.html`
5. Register the deployed `stripe-webhook` URL in Stripe and subscribe only to the required Checkout/payment events for the chosen payment mode. Verify signatures.
6. Test card success, decline, cancel, abandoned checkout, duplicate webhook delivery, webhook delay, hold expiry, refund, simultaneous attempts for the same dates, and combined booking rollback.
7. Switch to live mode only after all end-to-end tests pass.

## GitHub Pages frontend configuration
After deploying the `create-checkout-session` Edge Function, put its public URL into `BOOKING_API_URL` in `assets/main.js`. Only the public endpoint URL belongs there. Configure CORS to allow the exact production Pages origin and local development origin; do not use wildcard CORS for credentialed/private endpoints.

## Important schema note
`../supabase/schema.sql` is a starter design reference, not a complete production migration. Use `inventory_reservations` as the transactional reservation/locking table and its exclusion constraint to prevent overlapping active reservations. Add appropriate RLS policies and transaction functions before production.
