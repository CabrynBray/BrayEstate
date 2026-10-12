# Bray Estate — GitHub Pages Website

Rustic-and-elegant website starter for a Texas event venue with five independently bookable accommodations.

## Pages included
- `index.html` — homepage
- `events.html` — event types and venue details
- `stay.html` — five individual accommodation listings
- `booking.html` — booking form ready to connect to a booking API
- `map.html` — illustrative property site plan plus interactive OpenStreetMap map
- `contact.html` — contact form and venue contact details
- `assets/styles.css` — responsive styling
- `assets/main.js` — navigation, configuration, map, and booking API handoff
- `docs/BOOKING_BACKEND.md` — backend, Stripe, and availability integration checklist
- `docs/PRICING_PLAN.md` — custom package and accommodation pricing framework
- `supabase/schema.sql` — starter database schema reference (review before applying)

## Before launch
1. Replace `hello@example.com`, phone number, and contact address.
2. Replace the placeholder central-Texas map coordinates in `assets/main.js` with the actual property coordinates. A city or street address is needed for a reliable pin.
3. Update the concept site plan in `map.html` to match the real property and its accessible routes, parking, entrance, and buildings.
4. Replace the five sample stay names, photos, descriptions, occupancy, amenities, prices, policies, and availability.
5. Add venue capacity, included services, event policies, cancellation terms, check-in/out times, taxes/fees, accessibility information, and privacy policy.
6. Use `docs/PRICING_PLAN.md` to choose package inclusions and calculate real rates; its figures are planning placeholders, not live prices.
7. Review `supabase/schema.sql` with a developer before applying it. It is a starter reference, not a production-ready migration.
6. Verify the licenses and terms for remote images and map tiles.

## Important: GitHub Pages does not run the booking backend
The current booking form validates basic fields. Until an API is configured, it opens an email inquiry. It does not reserve inventory or collect payment.

For automatic booking and payment, use the implementation checklist in `docs/BOOKING_BACKEND.md` and the pricing framework in `docs/PRICING_PLAN.md`.

Recommended stack:
- **Frontend:** GitHub Pages (static website)
- **Database / availability:** Supabase Postgres, with constraints/transactions to prevent double booking
- **Server-side API:** Supabase Edge Functions or a Vercel serverless function
- **Payment:** Stripe Checkout, with secret key kept only in server-side secrets
- **Payment confirmation:** Stripe webhook updates the booking to paid/confirmed after verified payment
- **Email:** Resend, Postmark, or another transactional email provider for confirmations

Do not put Stripe secret keys, database service-role keys, or other private secrets in this repository or browser JavaScript.

## Connect the API
After deploying the server-side booking endpoint, set `BOOKING_API_URL` in `assets/main.js` to the public URL of that endpoint. The endpoint should accept the booking form JSON and return `{ "checkoutUrl": "https://checkout.stripe.com/..." }` only after it has validated dates, availability, guest limits, and the price on the server. See `docs/BOOKING_BACKEND.md`.

## Publish with GitHub Pages
1. Create a repository on https://github.com (for example `bray-estate`).
2. Upload the contents of this folder so `index.html` is at the repository root.
3. Open **Settings → Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Choose branch `main`, folder `/(root)`, and save.
6. Open the published URL shown on the Pages settings screen, typically `https://YOUR-USERNAME.github.io/bray-estate/`.

## Local preview
Open `index.html` in a browser, or use VS Code with Live Server.
