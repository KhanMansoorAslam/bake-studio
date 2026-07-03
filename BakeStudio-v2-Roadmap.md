# Anaam's Bake Studio — Enhancement Roadmap (v2.x)

*Prepared for: Anaam (founder) and Mansoor (maintainer). Written so any future engineer or AI session can pick up any single section and execute it without further context.*

## 1. Current State Summary

Anaam's Bake Studio is a single-file web app (`index.html`) hosted for free on GitHub Pages at `https://khanmansooraslam.github.io/bake-studio/`, backed by a Supabase free-tier project called "BakeStudio" (ref `bvgosgappwnzserrsfnk`, Asia-Pacific region). The whole system — frontend, auth, database, and file storage — runs on two free platforms with zero recurring cost, which is appropriate for a six-person family tool. Authentication is passwordless magic-link email with public signup disabled, so only the six manually created family accounts can ever log in; this is the correct security posture for a private family app and should not be loosened casually. Data lives in four tables — `profiles`, `recipes`, `bakes`, `reviews` — all protected by row-level security so each person can read everyone's content but only write their own, with a policy specifically preventing self-reviews to keep the "family critic" feature honest. Photos live in a private Storage bucket, one folder per user, accessed only via short-lived signed URLs. The feature set is already rich for a hobby project: 12 built-in halal recipes with precise gram measurements, custom recipe support, structured bake logging with per-step notes, a photo-based family review system, a rule-based "Bake Doctor" that diagnoses common failures, and seven computed badges that gamify participation. The known soft spots are all consequences of the free-tier choice: the Supabase project pauses after about seven days of inactivity and needs a manual "Restore" click, the built-in email sender is capped at a handful of magic links per hour (a real risk if two people try to log in around the same time), there are no automatic database backups, and email templates cannot be edited until custom SMTP is configured. Nothing here is urgent — the app works — but the roadmap below closes these gaps in priority order and adds a small amount of delight on top.

## 2. v2.0 "The Doorbell" — Join-Request Feature

**Goal.** Let a prospective family member (a cousin, a grandparent) ask to join from the public login screen, without ever exposing signup or giving anonymous users any access to real data. The owner account (Mansoor's) reviews requests inside the app and still approves manually in the Supabase dashboard — no automatic account creation, by design.

**Database.** Run this in the Supabase SQL editor:

```sql
create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  message text,
  created_at timestamptz not null default now(),
  status text not null default 'pending' check (status in ('pending','approved','declined'))
);

alter table public.join_requests enable row level security;

-- Anyone (including anonymous visitors) may submit a request, nothing else.
create policy "anon can insert join requests"
  on public.join_requests for insert
  to anon, authenticated
  with check (true);

-- Only the owner account may read pending requests.
create policy "owner can read join requests"
  on public.join_requests for select
  to authenticated
  using (auth.jwt() ->> 'email' = 'khanmansooraslam@gmail.com');

-- Only the owner account may delete (i.e. dismiss/clear) requests.
create policy "owner can delete join requests"
  on public.join_requests for delete
  to authenticated
  using (auth.jwt() ->> 'email' = 'khanmansooraslam@gmail.com');
```

No update policy is created deliberately — the owner deletes a request after acting on it rather than editing status in place, which keeps the table simple and avoids a stray "approved" row implying the person already has access when they don't.

**UI changes in `index.html`.** On the login screen, below the existing magic-link email input, add a small collapsed link/button labelled "Ask to join the family" that expands a short form: Name, Email, optional Message, and a Submit button. On submit, call `supabase.from('join_requests').insert({...})` using the existing anonymous Supabase client (no auth session needed, matching the anon insert policy) and show a confirmation like "Thanks! We'll be in touch." Inside the app's existing Family tab, add a "Pending Requests" panel that only renders when the logged-in user's email matches the owner address (check this client-side the same way other role-gated UI is hidden, e.g. `if (session.user.email === 'khanmansooraslam@gmail.com')`). This panel runs `supabase.from('join_requests').select('*').order('created_at')` and lists each request with its name, email, message, and a "Dismiss" button that deletes the row after the owner has manually added the person in the Supabase Auth dashboard and sent them their first magic link. Because the real security boundary is still "only manually created auth users can log in," this feature is purely a communication convenience layered on top of the existing safe model — it changes no trust assumptions.

## 3. v2.1 Custom SMTP Upgrade

**Why.** The Supabase built-in mailer is rate-limited to a few emails per hour total, shared across all users. A free Gmail SMTP relay removes that ceiling (Gmail allows roughly 500 sends/day) and unlocks editable email templates.

**Steps.**
1. In the Google account that will send mail (a dedicated address is cleaner than a personal one, but Mansoor's is fine), enable 2-Step Verification under Google Account → Security.
2. Still under Security, open "App passwords," choose app "Mail" and device "Other (Supabase)," and generate a 16-character app password. Copy it immediately; Google will not show it again.
3. In the Supabase dashboard, go to Project Settings → Authentication → SMTP Settings, toggle "Enable Custom SMTP," and fill in: Host `smtp.gmail.com`, Port `587`, Username = the full Gmail address, Password = the app password from step 2, Sender email = same Gmail address, Sender name = "Anaam's Bake Studio."
4. Click Save, then use the "Send test email" option if available (or simply trigger a real magic-link login) to confirm delivery. Check spam folders on first send and mark as "not spam" to improve future deliverability.
5. Once SMTP is confirmed working, go to Authentication → Email Templates → Magic Link. The template becomes editable. Update the body to present both options clearly, for example: "Click the button below to sign in, or enter this code on the sign-in screen: **{{ .Token }}**" alongside the existing `{{ .ConfirmationURL }}` link. Supabase generates `{{ .Token }}` as a six-digit one-time code tied to the same magic-link request, so this requires no backend changes — only that `index.html` optionally add a small "Enter code instead" input that calls `supabase.auth.verifyOtp({ email, token, type: 'email' })`. This is useful when a link gets mangled by a mail client or when someone is checking email on a different device than the one they're signing in on.
6. Document the Gmail app password somewhere safe (a password manager, not the repo) since it will need to be regenerated if 2-Step Verification is ever reset.

## 4. v2.2 Data Safety — Family Backup Export

Because the free Supabase plan has no automatic backups, the app should let the owner pull a full snapshot on demand. Add a button visible only to the owner account (same email check as section 2) inside the Family tab, labelled "Download family backup." On click, it runs four `select('*')` queries — one each against `profiles`, `recipes`, `bakes`, and `reviews` — combines the results into one JSON object keyed by table name, adds a `generated_at` timestamp, and triggers a client-side download using a `Blob` and a temporary `<a download>` link (no server involved, so no new backend code or storage cost). Name the file `bakestudio-backup-YYYY-MM-DD.json`. This export intentionally excludes Storage photo binaries — only the `photo_path` references are captured — because pulling every image through signed URLs client-side would be slow and is not needed to protect the structured data that matters most (recipes and bake history). If photo preservation is ever desired, that would be a distinct future task using the Storage list/download API rather than an extension of this button. Pair this feature with a simple habit rather than automation: put a recurring note on the family calendar for the first of each month reminding Mansoor to click the button and save the file to a personal cloud drive folder. This is deliberately manual and low-tech, matching the project's zero-infrastructure philosophy.

## 5. v2.3 Fun Layer — Three Session-Sized Features

**Star Baker of the Month crown.** Once a month (client-side, computed on page load by checking if it's a new calendar month since last computed, or simply computed live every time the Family or Badges view renders), tally the current calendar month's bakes per baker from the existing `bakes` table and reviews' star ratings, and award a small crown emoji next to the name of whoever has the most bakes (ties broken by average stars). No new table is needed — this is a pure read-and-compute feature layered onto data already fetched for the badges panel.

**Printable recipe card view.** Add a "Print" button on each recipe's detail view that opens a simplified, single-recipe layout (large font, ingredients and steps only, no navigation chrome) in a print-friendly `@media print` CSS block, then calls `window.print()`. This lets the family print a physical card for the kitchen counter without needing a PDF library or backend change.

**Bake-day countdown.** Add a small widget where any family member can set a target date and label (e.g. "Eid Cookies — 12 days to go") stored as a single row per user in a new lightweight table `countdowns (id, owner uuid, label text, target_date date)` with the same RLS pattern as `recipes` (read-all, write-own). The home screen shows the nearest upcoming countdown across the family, computed client-side as `target_date - today()`.

## 6. Maintenance Runbook

**Project paused.** Supabase free projects pause after roughly seven days with no API activity. Symptom: the app hangs or errors on login/data load. Fix: log into supabase.com, open the BakeStudio project, click "Restore project" on the paused-project banner, wait one to two minutes, then reload the app. No data is lost during a pause; this only affects availability.

**Someone is locked out.** Confirm their email is one of the six accounts created in Authentication → Users in the Supabase dashboard (email must match exactly, case-insensitive). If the magic link never arrives, first check spam, then check whether the hourly send limit was hit (a reason to prioritize the SMTP upgrade in section 3). As a manual fallback, the owner can open Authentication → Users, select the person, and use "Send magic link" directly from the dashboard.

**Adding or removing a family member.** To add: Authentication → Users → Add User, enter their email, leave password unset (magic-link only), then insert a matching row into `profiles` with their name, chosen emoji, and role. To remove: delete their row from `profiles` first (optional, for tidiness), then delete the user from Authentication → Users; their historical `recipes`, `bakes`, and `reviews` rows remain intact (owned by their user id) unless explicitly deleted, which preserves family history even after someone leaves.

**Updating the live app.** Edit `index.html` locally (or in an AI session), verify it opens correctly in a browser, then go to the GitHub repo `KhanMansoorAslam/bake-studio`, use the web "Upload files" (or "Edit this file") interface to replace `index.html`, and commit directly to `main` with a short message describing the change. GitHub Pages rebuilds automatically, and the live site reflects the update within about a minute — no build step, no local git tooling required.

## 7. Explicit Non-Goals

This roadmap deliberately excludes public access, payments, analytics, and social features beyond the family, and each exclusion is a considered choice rather than an oversight. Public access is off the table because the entire trust model — RLS policies, the six manually managed accounts, the review-your-own-bake block — assumes a closed, known set of users; opening signups would require rebuilding moderation, abuse handling, and content review from scratch for no benefit to Anaam's actual goal, which is a fun tool for her family. Payments are excluded because introducing money instantly creates legal, tax, and safety obligations (an 11-year-old founder should not be operating anything resembling a commercial transaction), and nothing about the current feature set needs monetization to be worthwhile. Analytics are excluded because a six-person family app has no meaningful "metrics" to optimize — everyone already knows who uses it — and adding a tracking script would only introduce a third-party dependency and a privacy question with no offsetting value. Social features beyond the family (public profiles, sharing bakes outside the household, comments from non-family visitors) are excluded because they would reintroduce the exact public-surface risks the closed-signup model was built to avoid, and they dilute the app's actual charm, which is that it's a private space for one family's baking hobby. If Anaam's Bake Studio ever grows beyond the family — a real possibility worth celebrating if it happens — that would warrant a full re-architecture conversation, not an incremental feature added to this codebase.
