# Stillday

Responsive static PWA. Deploy the `outputs/` directory directly to Netlify (`.` is the publish directory; no build command).

## Enable cross-device sync
1. In the Supabase project SQL Editor, run the current `supabase-setup.sql` (it creates the tasks and per-user preferences tables; it is safe to run again if you already created `tasks` with the earlier setup).
2. In Supabase Auth settings, enable email/password. Set the deployed Netlify URL as the Site URL and add it to Redirect URLs.
3. `supabase-config.js` contains the browser-safe project URL and publishable key. That key is public by design; row-level security protects data. Never put a service-role/secret key in this app.
4. Deploy this directory on Netlify, then sign in with the same account on each device.

Tasks are stored locally first and synced when online. If the database has not been set up or the network is unavailable, the local task flow remains usable. Local task records are imported when an account first syncs. Theme, Today-screen layout, Radar defaults, and editable life areas are stored locally first and sync to the account after sign-in. Add, rename, or remove life areas in Settings. Choose an area while capturing a thought or editing a task; unassigned tasks remain uncategorized. Horizon filters follow the life areas you define, while Everything always shows all areas.