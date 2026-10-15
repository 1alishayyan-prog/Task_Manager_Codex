# Stillday

Responsive static PWA. This GitHub repository contains the app at its root. Connect the repository to Netlify with the repository root as the publish directory; no build command is required.

## Enable cross-device sync
1. In the Supabase project SQL Editor, run the current `supabase-setup.sql` (it creates the tasks and per-user preferences tables; it is safe to run again if you already created `tasks` with the earlier setup).
2. In Supabase Auth settings, enable email/password. Set the deployed Netlify URL as the Site URL and add it to Redirect URLs.
3. `supabase-config.js` contains the browser-safe project URL and publishable key. That key is public by design; row-level security protects data. Never put a service-role/secret key in this app.
4. Deploy the repository root on Netlify, then sign in with the same account on each device.

Tasks are stored locally first and synced when online. If the database has not been set up or the network is unavailable, the local task flow remains usable. Local task records are imported when an account first syncs. Theme, text size (100–160%), Today-screen layout, Radar defaults, and editable life areas are stored locally first and sync to the account after sign-in. Text size defaults to 120%; adjust it in Settings → Appearance. Run the updated setup SQL once to add the `text_scale` column for cross-device text-size sync. Add, rename, or remove life areas in Settings. Choose an area while capturing a thought or editing a task; unassigned tasks remain uncategorized. Horizon filters follow the life areas you define, while Everything always shows all areas.


New visitors get optional example tasks from demo-tasks.json. They are copied into browser storage once, can be removed with the bin controls or Settings, and are not uploaded to an account. Signing in clears any remaining examples before syncing. Supabase Auth persists the session in this browser’s local storage; account names are stored as Auth user metadata, so no SQL schema change is required for display names.
