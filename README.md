# Baby Care Monitor - feed, sleep & diaper (single file, no Node)

One `index.html`. One email login holding **multiple profiles**, each with
up to 4 babies. Tracks **feeding, sleep, and diapers**, shows analytics vs
AAP/AASM standards, generates a **printable doctor summary**, and includes
a **local data assistant**. Supabase + Chart.js load from a CDN - nothing
compiles, no Node anywhere.

> Not a medical device. It logs care events and compares them to public
> population averages. Always defer to your pediatrician.

---

## Features

- **Feeding** - start/stop timer, ml logging, per-feed history, feed-gap
  reminders with browser notifications.
- **Sleep (automatic)** - sleep is the background state, inferred from the
  gap since the last feed. Starting a feed pauses sleep and saves the
  stretch that just ended; ending the feed resumes sleep automatically.
  Reliable even when your phone is locked, because it's gap-based rather
  than a live-counting timer. Day vs night split.
- **Diapers** - one tap for wet / dirty / both; daily counts and wet-vs-dirty.
- **Insights** - daily milk, sleep (day/night), diapers (wet/dirty), feed
  timing by hour, and standard-vs-actual for milk and sleep.
- **Doctor summary** - a printable per-baby report (feeding, sleep, diaper
  averages vs standards + a 14-day table). Use your browser's "Save as PDF".
- **Ask** - a local assistant that answers questions about your own logs
  ("last feed?", "sleep today?", "how is Baby A vs standard?"). Runs on
  your device; no data leaves the app, and it's not an LLM.
- **Profiles** - one account, many profiles, synced across every device
  signed into the same email.

## Standards used

- Milk ~150 ml/kg/day (120-180 range), cap ~960 ml/day (formula).
- Sleep per AAP/AASM: 14-17 h (0-3 mo), 12-16 h (4-11 mo), 11-14 h (1-2 yr).
- Diapers per AAP: ~8-12/day (0-3 mo), ~6-10 (4-11 mo), ~5-8 (1 yr+).

---

## Setup (about 20-30 min)

### 1. Supabase
1. supabase.com -> New project (name, DB password, region). Wait ~2 min.
2. SQL Editor -> New query -> paste all of `supabase-schema.sql` -> Run.
   **If you ran an earlier schema version**, first run the DROP block at the
   bottom of that file on its own, then run the whole file.
3. Authentication -> Sign In / Providers -> enable Email, turn "Confirm
   email" off.
4. Copy your **Project URL** (Project Settings -> Data API, or the Connect
   dialog) and **Publishable key** (Project Settings -> API Keys).

### 2. Put values in the file
Open `index.html`, replace the two lines in the CONFIG block near the top,
save. Double-click the file to test locally.

### 3. Host it
- **Netlify Drop:** drag `index.html` onto app.netlify.com/drop.
- **Vercel:** upload `index.html` to a GitHub repo (Add file -> Upload),
  then import the repo at vercel.com/new and Deploy. No build settings, no
  env vars (keys live in the file).

### 4. Point Supabase at the live URL
Authentication -> URL Configuration -> set **Site URL** and add a
**Redirect URL** = your live `https://...` URL (include `https://`). Save.

---

## How the sleep logic works (worth knowing)

Sleep isn't a button you press - it's assumed to be happening whenever the
baby isn't being fed. The app measures it as the time between the end of
one feed and the start of the next. When you start a feed, the stretch of
sleep that just ended is saved to the database (if it was 5+ minutes), so
it survives across devices. This means you only ever log the interruptions
(feeds and diapers) and sleep fills itself in - and it stays correct even
if the app was closed for hours.

Diaper changes are logged but do **not** cut the sleep clock (a quick
change mid-nap doesn't end the nap). Only feeds pause sleep.

If an auto-filled sleep stretch is wrong (e.g. you were out and baby was
awake), delete it from the Recent activity list on the Track tab.

---

## A note on the "AI assistant"

The Ask tab answers questions from your own logged data, computed in your
browser. It is deliberately **not** a large language model: putting a real
AI provider key into a public HTML file would expose it to anyone. If you
later want true LLM chat (free-form questions, advice-style answers), that
single feature needs a tiny serverless function to hold the key safely -
everything else stays as-is. Ask and it can be added.

---

## Privacy / security

Row-level security limits every signed-in user to their **own** profiles.
The publishable key in the file is safe to expose - it can only do what
those rules allow. Sharing across devices = signing into the same email.
This is the single-account model; other people signing in as *themselves*
and sharing a profile is the "invited members" version (a future add-on).

---

## Troubleshooting

- **"Almost there"** - CONFIG values not replaced. Edit and reload.
- **Sign-in link goes to a file path / localhost** - set Site URL in
  Supabase (step 4), include `https://`, request a fresh link.
- **"email rate limit exceeded"** - Supabase's built-in mailer is throttled;
  wait ~15-60 min and try once. (Or switch to email+password - ask.)
- **column "household_id" does not exist / other schema errors** - an older
  incompatible table exists. Run the DROP block at the bottom of the schema
  file first, then re-run the whole file.
- **Data doesn't sync across devices** - re-run the realtime lines at the
  end of the schema.
