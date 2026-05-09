# Google Play Store Listing — Reusable Checklists

Drafts for everything the Play Console will ask for. Edit before submitting.

---

## App name (max 30 chars)

```
Reusable Checklists
```
(19 chars)

## Short description (max 80 chars)

```
Simple, offline checklists you can reuse again and again.
```
(57 chars)

Alternates:
- `Minimalist offline checklists. Build once, reuse forever.` (57 chars)
- `Offline-first checklist app. Make a list once, check it off many times.` (71 chars)

## Full description (max 4000 chars)

```
Reusable Checklists is a minimalist, offline-first app for the lists you check off again and again — packing for trips, weekly groceries, pre-flight routines, gym splits, deploy steps. Make a list once. Check it off whenever you need it. Reset with a tap.

Built for speed and clarity, with no accounts, no ads, and nothing transmitted off your device.

FEATURES
• Create unlimited named checklists
• Add, remove, and edit items at any time
• Reorder items by drag and drop
• Check or uncheck individual items, or use Check All / Uncheck All to reset the entire list
• Visual progress indicator so you can see at a glance how far you are
• Undo support for accidental deletes
• Export and import your checklists as JSON for backup or sharing
• Light, dark, and system theme modes
• Material 3 design

PRIVACY-FIRST
• 100% offline — no internet required
• No accounts, no sign-in
• No analytics, no advertising, no tracking SDKs
• All data stored locally on your device

WHO IT'S FOR
Anyone who finds themselves rebuilding the same checklist from scratch each time. Travelers. Parents managing weekly errands. Pilots, climbers, and divers running through pre-activity checks. Engineers walking through release steps. Anyone whose brain is happier when the routine is on a screen, not in their head.
```

(~1,400 chars — leaves room to expand)

---

## Data safety form

When prompted in the Play Console:

| Question | Answer |
| :--- | :--- |
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | **N/A** (no data collected) |
| Do you provide a way for users to request that their data be deleted? | **Yes** — uninstalling the app or clearing app data deletes all stored content |

Result: a clean "No data collected, no data shared" disclosure on the listing.

---

## Content rating (IARC questionnaire)

Category: **Utility**

All standard content questions: **No** (no violence, sexual content, profanity, controlled substances, gambling, user-generated content, social features, location sharing, digital purchases).

Expected rating: **Everyone / 3+ / PEGI 3 / ESRB Everyone.**

---

## App category

- Category: **Productivity**
- Tags (Play allows up to 5): Productivity, Lists, Organization, Notes, Task Management

---

## Contact details

- **Email:** antmacchia15@gmail.com
- **Website:** *(optional — link to GitHub repo or a personal site if you have one)*
- **Phone:** *(optional, only required for some account types)*

---

## Privacy policy URL

The policy lives at `docs/PRIVACY.md` in this repo. To get a public URL, the simplest options are:

1. **GitHub Pages** — enable Pages on the repo (Settings → Pages → main branch / docs folder), then the URL is something like `https://amacchia.github.io/reusable_checklists/PRIVACY.html`. Will need to be `.html`, so either let Jekyll render the .md or commit a small `index.html`/`PRIVACY.html`.
2. **Raw GitHub URL** — `https://raw.githubusercontent.com/amacchia/reusable_checklists/main/docs/PRIVACY.md`. Works, but Play sometimes rejects raw text. Pages is safer.
3. **Gist** — paste the policy text into a public gist; use the gist URL.

Pages is what most indie developers use.

---

## Required graphics

| Asset | Spec | Status |
| :--- | :--- | :--- |
| App icon | 512×512 PNG, 32-bit | ✅ already have (`assets/icon/app_icon.png`) |
| Feature graphic | 1024×500 PNG/JPG, no transparency | ❌ need to create |
| Phone screenshots | min 2, max 8; 16:9 or 9:16; min 320px, max 3840px on each side | ❌ need to capture |
| 7-inch tablet screenshots | optional, but recommended | ❌ optional |
| 10-inch tablet screenshots | optional, but recommended | ❌ optional |

**Screenshot plan** (suggested set of 4-5 from the Pixel 9 Pro XL):

1. **Main screen** with 3-4 example checklists at varying progress (e.g., "Weekend Trip 6/8", "Groceries 0/12", "Pre-flight Check 12/12")
2. **Detail screen** of a checklist mid-progress, showing checked + unchecked items and the progress indicator
3. **Detail screen** showing drag-and-drop reorder in progress (item lifted)
4. **Detail screen** in dark mode (shows theming)
5. **Bulk actions / undo snackbar** in action

Capture from the device with `adb exec-out screencap -p > shot.png` or via Android's volume-down + power buttons.

**Feature graphic** is the banner shown at the top of the listing on Play. Common pattern: app name + a short tagline ("Reuse the routine.") on a solid color or subtle gradient, optionally with a stylized phone mockup. 1024×500 is small — keep it bold and readable. Can be made in any image tool; many devs use Figma or Canva.

---

## Release tracks

Recommended progression for the first launch:

1. **Internal testing** — upload AAB, add yourself as tester, install via Play link, verify the actual Play install/update experience works
2. **Closed testing** — optional, for a small group of beta testers
3. **Production** — public

Start with internal testing. The first review for a new app on production usually takes a few days; you don't want to discover an issue after you've waited.

---

## Pre-launch checklist (Play Console will run automatically)

After you upload the first AAB to internal testing, Play Console runs an automated pre-launch report on real devices: install, launch, basic interaction, accessibility scan, security scan. Worth checking the report before promoting to production — it sometimes catches issues you didn't.
