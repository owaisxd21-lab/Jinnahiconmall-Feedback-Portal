Jinnah Icon Mall Feedback Portal — Premium Edition

Netlify-ready static website with Supabase integration.

WHAT'S NEW IN THIS VERSION
- Customer-facing page now shows ONLY the feedback form. The "Admin Portal"
  button has been removed from the header so customers never see it.
- Admins reach the login page through a private link instead:
    https://YOUR-SITE.netlify.app/#admin
  Bookmark that link (with #admin at the end) for staff use. Logging out
  sends you back to the plain customer feedback page.
- Redesigned interface: navy + gold "VIP" theme, Fraunces + Inter typography,
  refined cards, animated hero, star-rating hover states, photo preview.
- Toast notifications instead of browser alert() popups.
- Loading spinners on submit, sign-in and dashboard load.
- Admin dashboard now includes:
  - KPI cards (total, today, average rating, resolved/pending)
  - Rating distribution, feedback-by-category, and top-areas breakdowns
  - Search, status filter, and sorting (newest/oldest/highest/lowest rating)
  - CSV export of all feedback
  - A "Needs Attention" panel listing every feedback rated below 3 stars
  - Delete feedback (removes the row and its uploaded photo) — owner only
  - Forgot-password flow for staff accounts
- Three access levels for the login, instead of a single admin role:
  - Owner: full access, including deleting feedback and managing everyone's
    access level from the new "Team & Access" panel.
  - Admin: can view feedback and, after reviewing it, add/edit the admin
    remark only — cannot change status, delete, or manage access.
  - User (Viewer): read-only access to the whole dashboard, no changes.
  New accounts still start as "pending" until the owner approves them.
- schema.sql now enforces these three tiers (re-run schema.sql in Supabase
  SQL Editor to apply — see SETUP.md for the one-time upgrade step).

IMPORTANT: Before publishing/using the portal, run schema.sql in the Supabase
SQL Editor (even if you ran an older version before — it's safe to re-run).

Supabase URL and publishable key are already present in index.html.
Do not put a Supabase service-role/secret key in this website.
