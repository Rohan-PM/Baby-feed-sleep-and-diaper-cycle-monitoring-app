# Baby Care Monitor v4 (single file, no Node)

A mother-first baby tracker: one `index.html`, one email login, multiple
profiles. Tracks feeding, sleep, diapers, weight/growth, and prescriptions,
with WHO/AAP standards, a printable doctor summary, and a local assistant.
Supabase + Chart.js load from a CDN - nothing compiles, no Node anywhere.

> Not a medical device. Compares logs to public population averages.
> Always defer to your pediatrician.

## The home screen (redesigned)
Each baby is one card showing, at a glance:
- **Asleep / Feeding status** with a live clock - sleep runs automatically
  in the background (time since the last feed). No button needed to "start"
  sleep; it's the default state.
- **Feed:** three real buttons - **Breast** (timer, optional L/R side, no
  ml), **Expressed** (ml), **Formula** (ml). Breast is the no-number path
  by design.
- **Diaper:** Wet / Dirty / Both, one tap.
- **Remind** - hand off a next-feed reminder to your phone's Calendar.

Starting a feed marks baby awake and saves the sleep that just ended;
finishing resumes sleep automatically. Diapers don't interrupt sleep.

## Tabs (bottom bar)
- **Home** - log everything, see current status.
- **Insights** - plain-language "today" summary, then charts (milk, sleep
  day/night, diapers wet/dirty).
- **Growth** - log weight over time, plotted on the **WHO weight-for-age**
  curve (median + 3rd/97th bands) with the latest percentile. WHO is the
  standard used in India for under-5s.
- **Doctor** - printable summary: weight + percentile, feeding (incl.
  breast %), sleep, diapers, **next well-baby visit** (6-week, 2/4/6/9/12/
  15/18/24-month schedule), and a 14-day table. Print / Save as PDF.
- **More** - Ask assistant, prescription upload, feed-reminder settings,
  auto-reminder toggle, and baby setup (name, DOB, sex, weight, colour).

## Prescriptions (storage)
Photograph and store prescriptions privately in your account, organized by
date and baby. Tap View to open the original image. The app stores the
image only - it does not transcribe the text (that would need a server and
carries real accuracy risk for drug names/doses; see note below).

## Setup

### 1. Supabase
1. New project. SQL Editor -> paste all of `supabase-schema.sql` -> Run.
   Upgrading from an older version? Run the DROP block at the bottom first.
2. Authentication -> Sign In / Providers -> enable Email, turn "Confirm
   email" off.
3. **Storage** (for prescriptions): Storage -> New bucket named
   `prescriptions`, keep it **private** (Public off). Then add a policy so
   users access their own files - Storage -> Policies -> New policy on the
   bucket, FOR ALL to role `authenticated`, using:
   `bucket_id = 'prescriptions' AND owner = auth.uid()` (and the same for
   with-check). Supabase's policy templates can generate this.
4. Copy your Project URL and Publishable key.

### 2. Put values in the file
Paste them into the CONFIG block near the top of `index.html`, save.

### 3. Host
Netlify Drop, or upload to GitHub and import on Vercel. No build settings,
no env vars (keys live in the file).

### 4. Point Supabase at the live URL
Authentication -> URL Configuration -> Site URL + Redirect URL = your live
`https://...` URL.

## On weight, sex, and percentiles
Percentiles differ for boys and girls, so set each baby's **sex** (More ->
Edit baby) to see growth percentiles. Uses WHO Child Growth Standards LMS
values (0-24 months) with interpolation - the same method clinicians use.

## On the "AI"/transcription
The Ask tab answers from your own logs, in your browser (not an LLM). True
prescription transcription (image -> text) is deliberately NOT included: it
needs a server to hold an AI key safely, and mis-reading a drug name or
dose is a real safety risk. Prescriptions are stored as images to read
yourself. If you later want transcription, it needs one small serverless
function - ask and it can be added as a follow-up.

## Privacy / security
Row-level security limits every signed-in user to their own profiles;
prescription images sit in a private bucket scoped to your account. The
publishable key in the file is safe to expose - it can only do what the
rules allow. Sharing across devices = signing into the same email.

## Troubleshooting
- **"Almost there"** - CONFIG values not replaced.
- **permission denied for table ...** - policies didn't apply; re-run the
  whole schema (drop block first if upgrading).
- **Prescription upload fails** - the `prescriptions` storage bucket or its
  policy isn't set up (see Setup step 3).
- **No growth percentile** - set the baby's sex (More -> Edit baby).
- **Sign-in link -> localhost / file path** - set Site URL in Supabase.
- **email rate limit exceeded** - built-in mailer is throttled; wait and
  retry, or switch to email+password (ask).
