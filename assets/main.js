// Bray Estate site configuration.
// Replace the contact details and Texas placeholder coordinates before launch.
const VENUE_EMAIL = "hello@example.com";
const VENUE_PHONE_TEXT = "(000) 000-0000";
const VENUE_PHONE_LINK = "+10000000000";

// Real-world location placeholder: central Texas. Replace with your actual property coordinates.
const VENUE_LOCATION = { lat: 31.0, lng: -99.0, label: "Bray Estate — update with the real address" };

// Optional production booking API endpoint, e.g. a deployed Vercel or Supabase function URL.
// Leave blank until the backend is deployed and configured.
const BOOKING_API_URL = "";

document.querySelectorAll("[data-year]").forEach(el => el.textContent = new Date().getFullYear());
document.querySelectorAll("[data-venue-email]").forEach(el => el.textContent = VENUE_EMAIL);
document.querySelectorAll("[data-venue-email-link]").forEach(el => el.href = `mailto:${VENUE_EMAIL}`);
document.querySelectorAll("[data-venue-phone-text]").forEach(el => el.textContent = VENUE_PHONE_TEXT);
document.querySelectorAll("[data-venue-phone]").forEach(el => el.href = `tel:${VENUE_PHONE_LINK}`);

const toggle = document.querySelector(".menu-toggle");
const nav = document.querySelector(".nav");
if (toggle && nav) {
  toggle.addEventListener("click", () => {
    const open = nav.classList.toggle("nav-open");
    toggle.setAttribute("aria-expanded", String(open));
  });
}

const params = new URLSearchParams(window.location.search);
const typeSelect = document.querySelector("#bookingType");
const unitSelect = document.querySelector("#unit");
if (typeSelect && ["event", "stay", "both"].includes(params.get("type"))) typeSelect.value = params.get("type");
if (unitSelect && params.get("unit")) unitSelect.value = params.get("unit");

// Contact form demo: prepares an email. Use a form provider or backend for true submissions.
document.querySelectorAll("[data-mail-form]").forEach(form => {
  form.addEventListener("submit", event => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    const lines = [];
    new FormData(form).forEach((value, key) => lines.push(`${key}: ${value}`));
    const status = form.querySelector(".form-status");
    if (status) status.textContent = `Opening an email draft to ${VENUE_EMAIL}.`;
    window.location.href = `mailto:${VENUE_EMAIL}?subject=${encodeURIComponent(form.dataset.subject || "Bray Estate inquiry")}&body=${encodeURIComponent(lines.join("\\n\\n"))}`;
  });
});

// Booking form is designed to hand off to a server-side booking/payment API.
// Never calculate final prices or trust availability in the browser.
const bookingForm = document.querySelector("#bookingForm");
if (bookingForm) {
  bookingForm.addEventListener("submit", async event => {
    event.preventDefault();
    if (!bookingForm.reportValidity()) return;
    const status = document.querySelector("#bookingStatus");
    const data = Object.fromEntries(new FormData(bookingForm).entries());
    if (data.endDate < data.startDate) {
      status.textContent = "Please choose an end/check-out date that is the same as or later than the start date.";
      return;
    }
    if (data.bookingType === "stay" && !data.unit) {
      status.textContent = "Please select one of the five accommodations, or add a no-preference option.";
      return;
    }
    if (!BOOKING_API_URL) {
      const body = [
        "Bray Estate booking inquiry",
        `Booking type: ${data.bookingType}`,
        `Accommodation: ${data.unit || "No preference / not applicable"}`,
        `Start/check-in: ${data.startDate}`,
        `End/check-out: ${data.endDate}`,
        `Guests: ${data.guests}`,
        `Event type: ${data.eventType || "Not specified"}`,
        `Name: ${data.name}`,
        `Email: ${data.email}`,
        `Phone: ${data.phone || "Not provided"}`,
        `Notes: ${data.notes || "None"}`
      ].join("\\n\\n");
      status.textContent = `Booking backend not connected yet. Preparing an inquiry email to ${VENUE_EMAIL}; this does not reserve dates or charge a payment.`;
      window.location.href = `mailto:${VENUE_EMAIL}?subject=${encodeURIComponent("Bray Estate booking inquiry")}&body=${encodeURIComponent(body)}`;
      return;
    }
    status.textContent = "Checking availability and preparing secure checkout…";
    try {
      const response = await fetch(BOOKING_API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || "Unable to start booking.");
      if (!result.checkoutUrl) throw new Error("The booking service did not return a checkout URL.");
      window.location.assign(result.checkoutUrl);
    } catch (error) {
      status.textContent = `${error.message} Please contact Bray Estate to continue.`;
    }
  });
}

// Interactive OpenStreetMap via Leaflet. This is only a placeholder pin until real coordinates are entered.
function initLocationMap() {
  const el = document.getElementById("locationMap");
  if (!el || !window.L) return;
  const map = L.map(el).setView([VENUE_LOCATION.lat, VENUE_LOCATION.lng], 6);
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);
  L.marker([VENUE_LOCATION.lat, VENUE_LOCATION.lng]).addTo(map).bindPopup(VENUE_LOCATION.label).openPopup();
}
window.addEventListener("load", initLocationMap);
