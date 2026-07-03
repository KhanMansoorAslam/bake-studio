# Anaam's Bake Studio — Project Handover (public-safe)

This document lets any engineer or AI session maintain the project with zero prior context.
Family email addresses are deliberately NOT listed here; they live in the Supabase dashboard
(Authentication → Users) and in the owner's private local copy.

## The live system

- **Live app:** https://khanmansooraslam.github.io/bake-studio/
- **Code:** this repository, single file `index.html`, branch `main`, served by GitHub Pages.
- **Current live code (always fetch before editing):**
  https://raw.githubusercontent.com/KhanMansoorAslam/bake-studio/main/index.html
- **Deploying an update:** edit `index.html`, upload via GitHub web ("Add file" → "Upload files"),
  commit to `main`. Pages republishes in about a minute. Never force-push, never rename the file.

## Backend (Supabase, free plan)

- Project **BakeStudio**, ref `bvgosgappwnzserrsfnk`, region Asia-Pacific.
- Project URL: `https://bvgosgappwnzserrsfnk.supabase.co`
- Publishable key (public by design, already in index.html): `sb_publishable_M_M9Bvl6XXLCHHjoMu2o-A_kRxJU0EL`
- Dashboard: https://supabase.com/dashboard/project/bvgosgappwnzserrsfnk (owner signs in with GitHub)
- Schema: `profiles`, `recipes`, `bakes`, `reviews` — see `setup.sql` in this repo. Row-level
  security everywhere; users write only their own rows; **reviewing your own bake is blocked
  at the database level** and this rule is permanent.
- Storage: private bucket `photos`, per-user folders, signed URLs, no public access ever.
- Auth: passwordless magic-link email (`signInWithOtp`, `shouldCreateUser:false`); public
  signups are OFF; members are added manually by the owner in the dashboard (Add user,
  auto-confirm on, random unused password). Six family members are enrolled.

## Known free-tier limits

- Project pauses after ~7 days idle → dashboard → Restore (one click, lossless).
- Built-in email: a few magic links per hour → fix is Gmail SMTP (spec in roadmap).
- No automatic DB backups → backup-button spec in roadmap.
- Email templates editable only after custom SMTP.

## Documents in this repo

- `PROJECT-HANDOVER.md` — this file
- `BakeStudio-v2-Roadmap.md` — agreed enhancement backlog with specs and SQL
- `DEPLOY-GUIDE.md` — original deployment walkthrough
- `setup.sql` — database bootstrap (already executed once; do NOT run again on this project)

## Rules of engagement

1. Read the roadmap before building; parked features already have agreed specs.
2. One change at a time; verify syntax before deploying; never break login.
3. Schema changes only via SQL the owner runs himself in the SQL Editor.
4. Never expose the secret key, never enable public signups, never make the photos bucket public.
5. The app stays a single file; recipes stay halal and exact-measurement.
6. Anaam (age 11) is the founder; her father Mansoor is the owner and sole keeper of access.
