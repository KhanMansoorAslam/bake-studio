# Anaam's Bake Studio — Deploy Guide (about 30 minutes)

Three files are involved:
- **index.html** — the app itself
- **setup.sql** — one script that builds the database and security rules
- this guide

Anaam should watch every step. This is how the internet actually gets made.

---

## Part 1 — Supabase (Baba, ~10 min)

1. Open your Supabase project dashboard at https://supabase.com/dashboard
2. Left menu → **SQL Editor** → **New query**. Open `setup.sql`, copy ALL of it, paste, press **Run**. You should see "Success. No rows returned."
3. Left menu → **Authentication** → **Sign In / Providers** (or "Providers"): find **"Allow new users to sign up"** and turn it **OFF**. This is the lock on the front door — nobody on earth can create an account except you.
4. Left menu → **Authentication** → **Users** → **Add user** → **Create new user**. Create one per family member with their email and a password you choose together. **Tick "Auto Confirm User"** each time. Suggested list: Anaam, you, her mother, Amina, Taimoor, Ramesha.
5. Left menu → **Project Settings** → **API** (sometimes called **API Keys**):
   - Copy the **Project URL** (looks like `https://abcdxyz.supabase.co`)
   - Copy the **anon / public** key (in newer dashboards it may be called the **publishable** key)

## Part 2 — Paste the keys (Baba + Anaam, ~2 min)

1. Open `index.html` in Notepad (right-click → Open with → Notepad)
2. Near the top of the `<script>` section find:
   ```
   const SUPABASE_URL      = "PASTE_YOUR_PROJECT_URL_HERE";
   const SUPABASE_ANON_KEY = "PASTE_YOUR_ANON_PUBLIC_KEY_HERE";
   ```
3. Replace the placeholder text with your real URL and key (keep the quote marks). Save.

> Is it safe for this key to be visible? Yes. The anon key is designed to be public — all the real protection is the security rules from setup.sql plus signups being off. Nobody without a login you created can read or write anything.

## Part 3 — Publish with GitHub (Baba + Anaam, ~10 min)

1. Open **GitHub Desktop** → **File → New repository**. Name: `bake-studio`. Create.
2. Click **Show in Explorer** and copy `index.html` (with the keys pasted in) into that folder.
3. Back in GitHub Desktop: write a summary like "Anaam's Bake Studio v1" → **Commit to main** → **Publish repository**. **UNTICK "Keep this code private"** (GitHub Pages on a free account needs a public repository — safe for the reason above).
4. Go to the repository on github.com → **Settings** → **Pages** (left menu) → under "Branch" choose **main** and **/ (root)** → **Save**.
5. Wait 1–2 minutes. The page shows your live address:
   `https://YOUR-GITHUB-USERNAME.github.io/bake-studio/`

## Part 4 — Grand opening (Anaam, forever)

1. Open the address on any phone. Log in with your email and password.
2. Make your baker card, add your photo from the Family tab.
3. Send the address to the family group. Everyone logs in with the account Baba made them.
4. Bake something. Log every step. Make history. 🧁

---

## If something goes wrong

- **"Setup needed" warning on the login page** → the URL/key were not pasted or saved in index.html.
- **Login fails** → check the user exists in Supabase → Authentication → Users, and was Auto-Confirmed. You can set a new password there too.
- **App loads but stays empty / errors** → most likely setup.sql was not run, or ran twice (it must run exactly once on a fresh project).
- **Everything worked, then weeks later it does not** → the free Supabase project pauses after ~7 days of no use. Dashboard → your project → **Restore**. Nothing is lost.
- **Updating the app later** → replace index.html in the repo folder, commit, push. The site updates itself in about a minute.

## Monthly safety habit (2 minutes)

Supabase Dashboard → **Database** → **Backups** are not included on the free plan, so once a month: **Table Editor** → each table → export CSV. Or simply ask Claude to add an in-app backup button in version 1.1.
