# Bray Estate pricing planner
## Custom packages for events + independently bookable stays

This is a **planning framework, not a market appraisal**. Because the estate's town, capacity, amenities, and operating costs are not yet known, the example figures below are placeholders to test—not published prices. Check comparable venues within the eventual drive-time market before launch.

## 1. Separate the products

Keep three bookable products distinct:
1. **Event venue package** — date/time access to the event spaces and clearly listed inclusions.
2. **Accommodation reservation** — one of five units, booked by the night, with its own availability and checkout rules.
3. **Combined event + stay package** — an event package plus selected rooms/nights, optionally with a transparent bundle benefit.

A combined package must reserve both the event space and each selected accommodation. A guest should be able to book a stay without booking an event, and a separate event guest should not be able to book the same room dates.

## 2. Event packages to test

Use a package structure so guests can compare options without requiring a completely custom quote for every inquiry.

| Package | Best for | Possible inclusions to define | Pricing approach |
|---|---|---|---|
| **Estate Gathering** | birthdays, family reunions, showers, small celebrations | agreed-hour venue access, standard tables/chairs, basic cleanup, parking | fixed base fee by day/season, plus overtime |
| **Wedding at Bray** | ceremonies and receptions | ceremony + reception access, setup window, getting-ready space if available, event coordinator only if staffed | premium date-based package; itemize optional services |
| **Work & Retreat** | meetings, workshops, team retreats | meeting layout, Wi-Fi/AV only if provided, breaks/extended access | weekday rate or per-attendee add-on |
| **Full Estate Weekend** | multi-day weddings or reunions | defined venue access windows plus selected accommodations | venue fee + room-night total, optionally a small disclosed bundle saving |
| **Custom Celebration** | unusual layouts or event needs | scope confirmed in a written quote | base venue fee + priced add-ons |

For each package, state the maximum guest count, access start/end times, included setup/cleanup, furniture, indoor/outdoor spaces, parking, sound rules, vendor rules, security/staffing, weather backup, taxes, deposit, and cancellation schedule. Do not advertise amenities until confirmed.

## 3. Accommodation pricing

Set a separate nightly rate for each of the five units after confirming sleeping capacity, beds, bathrooms, privacy, accessibility, and amenities. Start with:
- **Base nightly rate** by unit.
- **Day-of-week adjustment** (e.g., Friday/Saturday vs. Sunday–Thursday).
- **Season/holiday adjustment** where local demand supports it.
- **Minimum stay** rules for high-demand dates, if appropriate.
- **Cleaning fee** only if needed, shown before checkout.
- **Extra-guest fee** only above a clearly stated included occupancy.
- **Taxes** calculated based on the property's jurisdiction and booking type.

Avoid setting prices solely by copying a competitor. Calculate a floor price from cleaning/turnover labor, utilities, supplies, maintenance reserve, platform/payment fees, taxes, and desired margin.

## 4. Illustrative starting tests (not final recommendations)

These are broad placeholders for modelling only; validate them against comparable properties once the town is known.

| Product | Placeholder test range |
|---|---:|
| Small gathering / weekday venue package | $1,000–$2,500 |
| Standard event package | $2,500–$6,000 |
| Premium wedding / peak-date package | $5,000–$12,000+ |
| Accommodation per unit, per night | $120–$300 |
| Combined package benefit | 0–5% of eligible venue + room subtotal |

These ranges may be too high or too low for the actual property. The correct rate depends heavily on local competition, capacity, season, what is included, and operating costs. Do not put these test ranges on the live website until validated.

## 5. Pricing formula and checkout display

Use server-side price calculation only:

`subtotal = event_package_price + sum(unit_nightly_rate × nights) + approved_add_ons + fees`

Then calculate applicable taxes and any approved discount. Display a line-item quote:
- Package(s) and date/time
- Number of nights and unit names
- Add-ons
- Discount (if any)
- Cleaning/service fees
- Applicable taxes
- Total
- Deposit due now and balance due date
- Refund/cancellation policy

Do not accept a total or unit price sent by the browser as authoritative. The browser sends selected package IDs, dates, unit IDs, guest counts, and add-ons; the server looks up the current price in the database.

## 6. Deposit and cancellation policy to decide

A reasonable decision framework—not legal advice:
- **Event reservation:** collect a clearly disclosed retainer/deposit at booking; set a balance due date before the event.
- **Stays:** choose full payment at booking or a deposit plus balance due before arrival.
- **Damage/security deposit:** if used, clearly distinguish it from the booking payment and determine how it will be authorized/refunded.
- **Cancellation:** publish deadlines and refund amounts for events and stays separately.
- **Date changes:** explain whether a rebooking fee or rate difference applies.
- **Failed/expired checkout:** release the temporary inventory hold automatically.

Ask a Texas tax professional or local authority which state/local hotel occupancy, sales, and event-related taxes apply to each product.

## 7. Availability rules to start with

- All dates/times use the estate's local time zone, likely a Texas time zone selected from the confirmed address.
- Stays use **check-in inclusive, checkout exclusive**: a guest checking out on June 12 does not block the next guest checking in June 12, subject to cleaning/turnover rules.
- Each accommodation is its own inventory item and can be booked independently.
- One event-space inventory item cannot have overlapping confirmed bookings or active payment holds.
- If the venue has multiple truly independent spaces, model each as a separate inventory item; if the whole estate must be exclusive, reserve a parent/estate-wide resource too.
- Set a short checkout hold (e.g., 10–15 minutes), then expire it if payment is not completed.
- Add cleaning/setup buffers where required. For example, block a stay unit until its turnover period ends; block the venue for setup and cleanup windows, not only guest-facing hours.
- A booking is **confirmed only after a verified Stripe webhook** says payment succeeded; never trust a success-page visit.
- Re-check availability immediately before creating a payment session and again when finalizing payment/hold state.
- Define maximum occupancy, minimum notice, booking horizon, minimum nights, event end times, quiet hours, and blackout dates before launch.

## 8. What is needed to finalize the numbers

1. Exact town or nearest town (for local competitors and tax jurisdiction).
2. Venue capacity, indoor/outdoor spaces, and what is included.
3. Sleeping capacity and amenities for each of the five stays.
4. Estimated fixed costs, per-event staffing/cleaning, and per-stay turnover costs.
5. Target positioning: affordable, mid-market, or premium.
