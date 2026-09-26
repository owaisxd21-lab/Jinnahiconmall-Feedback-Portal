# Jinnah Icon Mall — Online Feedback Portal Setup

This package is designed for the real requirement: customers can submit feedback from any device and approved admins can review the same central feedback from any computer.

## 1. Create the Supabase project
Open the official Supabase website and create a project.

## 2. Create the database/security
In Supabase Dashboard → SQL Editor, paste and run **schema.sql**.

## 3. Create the first owner
In Supabase Dashboard → Authentication → Users, create a user with an email and password — this will be the portal owner.

Then in SQL Editor run:

update public.profiles
set role='owner'
where id=(select id from auth.users where email='YOUR_OWNER_EMAIL');

Replace YOUR_OWNER_EMAIL with the actual email.

New accounts created later start as `pending` and have no dashboard access. This prevents anybody who discovers the login mechanism from automatically getting in. The owner approves new accounts and sets their access level from the **Team & Access** panel on the dashboard itself — no SQL needed after this first one-time step.

### Access levels
- **Owner** — full access: view feedback, change status, add remarks, delete feedback, export CSV, and manage everyone's access level (including approving new pending accounts).
- **Admin** — can view feedback and, after reviewing it, add/edit the admin remark. Cannot change status, delete feedback, or manage access levels.
- **User (Viewer)** — read-only: can view the dashboard and every feedback entry, but cannot add remarks, change status, or delete anything.

## 4. Connect the website
In Supabase Dashboard → Project Settings → API, copy:
- Project URL
- Publishable key

Open **index.html** and replace:

PASTE_YOUR_SUPABASE_URL_HERE
PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE

Do NOT put a service_role/secret key into index.html.

## 5. Test locally
Double-click index.html. Submit a customer feedback and then log into Admin Portal. The feedback should appear in the dashboard.

## 6. Put it online
You can deploy the project folder to a static host such as Vercel. Vercel currently supports dropping a folder/zip through its Vercel Drop workflow.

After deployment, use the live URL for customers and create a QR code pointing to that URL.

## 7. Important production notes
- Use a custom domain if your company wants one.
- Keep the Supabase publishable key in the frontend; never expose a service-role/secret key.
- Keep the RLS policies in schema.sql enabled.
- The database is central, so multiple computers see the same feedback.
- For a stronger production setup, admin creation should be controlled by a designated administrator rather than open public registration.
