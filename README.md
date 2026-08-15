# Twin Feed Monitor - single file, multi-profile (no Node, no build)

One `index.html`. One email login. That login can hold **multiple
profiles** ("profile sources") - each profile is its own set of babies
with its own feeds and history. Sign in on any phone with the same email
and every profile is there, syncing live.

Supabase and Chart.js load from a CDN, so **nothing compiles and there is
no Node.js anywhere**.

> Not a medical device. It logs feeds and compares them to public
> population averages. Always defer to your pediatrician.

Time: about **20-30 minutes**.

---

## How the model works

- You sign in once with your email.
- You create one or more **profiles** (e.g. "The Twins", "Grandma's
  house"). Each profile is private to your account.
- Each profile holds up to **4 babies** (name + colour + DOB + weight),
  their feed timers, ml logs, alerts, and analytics.
- Switch profiles from the dropdown at the top. Any device signed into
  the same email sees the same profiles and data, updated live.

This is the "one account, many profiles, many devices" model. Everything
is private to your login - nobody else can see it unless they sign in as
you.

---

## What's in this folder

- `index.html` - the entire app
- `supabase-schema.sql` - paste-and-run to create your database

---

## Step 1 - Supabase (database + login)

Free account at https://supabase.com.

1. **New project.** Dashboard -> New project. Name it, set a database
   password (save it), pick a nearby region, create. Wait ~2 min.
2. **Create the tables.** Left sidebar -> SQL Editor -> New query. Open
   `supabase-schema.sql`, copy all of it, paste, Run. Expect "Success."
3. **Email login on.** Authentication -> Sign In / Providers. Ensure
   Email is enabled; turn "Confirm email" **off** (so the link signs you
   straight in).
4. **Copy two values.** Project Settings (gear) -> API Keys (and Data API
   for the URL):
   - Project URL: `https://YOUR-PROJECT-ID.supabase.co`
   - Publishable key: starts `sb_publishable_...` (a legacy `anon` key
     also works)

---

## Step 2 - Paste your values into the file

Open `index.html` in any plain-text editor. Near the top, in the CONFIG
block, replace both lines with your real values and save:

```html
window.SUPABASE_URL = "https://YOUR-PROJECT-ID.supabase.co";
window.SUPABASE_PUBLISHABLE_KEY = "sb_publishable_xxxxxxxx";
```

**Test now:** double-click `index.html`. Sign in with your email, click
the link, create a profile, add a baby, log a feed, refresh. If it's all
still there, it's working.

> These keys are meant to be public. The publishable key can only do what
> your database security rules allow, and those rules limit every user to
> **their own** profiles. Safe to sit in the HTML.

---

## Step 3 - Host it (pick ONE, both drag-and-drop)

**Netlify Drop (simplest):** go to https://app.netlify.com/drop and drag
`index.html` onto the page. Instant public URL. Free account lets you
rename it and update later.

**Vercel (via GitHub web, no terminal):**
1. github.com/new -> name it `twin-feed`, check "Add a README file",
   create.
2. Add file -> Upload files -> drag in `index.html` (and the SQL) ->
   Commit.
3. vercel.com/new -> sign in with GitHub -> Import the repo -> Deploy.
   No build settings, no environment variables (the keys are in the file).

---

## Step 4 - Point Supabase at your live URL

Authentication -> URL Configuration: set **Site URL** to your live URL and
add it to **Redirect URLs**. Save. Now sign-in links return to the live
site instead of a file path.

Open the URL, sign in, and have your other devices sign in with the same
email. Same profiles everywhere.

---

## Everyday use

- **Add a profile:** the "+ New" button by the dropdown.
- **Rename / delete a profile:** the "Manage" button.
- **Add / rename / recolour / remove a baby:** the Babies tab (Edit on
  each baby, or "+ Add a baby").
- **Update the app:** re-drop the file on Netlify, or edit it on GitHub
  for Vercel. No build, ever.
- **Phone home screen:** open the URL -> Share -> "Add to Home Screen."

---

## Privacy / security

Database security (row-level security) limits every signed-in user to
their **own** profiles - so your data is private to your login. Because
this is the single-account model, sharing across devices means signing
into the same email on each device. If you ever want *other people's*
logins to see a profile (a partner signing in as themselves), that's the
"invited members" model - a bigger change; ask and it can be added.

---

## Troubleshooting

- **"Almost there" screen** - CONFIG values not replaced. Edit and reload.
- **Sign-in link goes to a file path / localhost** - set Site URL in
  Supabase (Step 4), request a fresh link.
- **Feeds or babies don't sync across devices** - re-run the schema's
  realtime lines (`alter publication supabase_realtime add table ...`).
- **"row-level security" error when saving** - you're not signed in, or
  the schema didn't finish. Re-run `supabase-schema.sql`.
- **Old v1 data present** - the old flat schema isn't compatible; see the
  note at the bottom of `supabase-schema.sql` to drop it.
