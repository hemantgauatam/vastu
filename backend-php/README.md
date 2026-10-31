# Kubar Vastu PHP + MySQL backend

This is the production backend for the Flutter app and its existing web admin panel. It preserves the previous API contract, so the Flutter UI can use it without code changes.

## Requirements

- PHP 8.0+ with `pdo_mysql`, `curl`, `json`, and `openssl`
- MySQL 8.0+ or MariaDB 10.4+
- Apache with `mod_rewrite`, Nginx, or PHP's built-in server

## Setup

1. Copy `backend-php/.env.example` to `backend-php/.env` and set the MySQL credentials and a strong admin password.
2. Start the backend. It automatically creates the configured database, all missing tables, indexes, and default settings. On shared hosting where PHP cannot create databases, create an empty database in the hosting panel first; its tables will still be created automatically.
3. Start the API:

   ```powershell
   powershell -ExecutionPolicy Bypass -File backend-php/start-local.ps1
   ```

4. Check `http://localhost:4000/health`; the PHP admin portal is at `http://localhost:4000/admin`.
5. Flutter uses `https://admin.kubervastu.com/public` by default. Override it locally with `flutter run --dart-define=BACKEND_URL=http://localhost:4000`.

Use `http://10.0.2.2:4000` for an Android emulator, or the computer's LAN IP for a physical phone.

This computer also has a password-protected MySQL 8 service on port 3306. The local XAMPP deployment therefore uses MariaDB on port 3307. After Windows restarts, launch it with `backend-php/start-xampp-database.ps1` before opening the admin portal.

## Apache / Nginx

Point the document root to `backend-php/public`. For Apache, enable `mod_rewrite` and `AllowOverride All`. For Nginx, route missing files to `index.php`. Ensure `public/uploads` is writable by PHP.

## Included features

- Registration, login, bearer sessions, logout, and profiles
- Remedies, orders, Razorpay checkout/signature verification, and one-year validity
- Blogs, videos, testimonials, media uploads, and moderation
- App-update settings and cookie-authenticated admin CRUD
- Paid-order email notifications with customer, remedy, amount, and payment details
- Self-contained PHP admin portal for users, remedies, orders, payments, blogs, videos, testimonials, uploads, and app releases
- Prepared SQL, password hashing, payment transactions, validation, CORS, and JSON errors

Database migrations run automatically when `AUTO_MIGRATE=true` (the default). They are recorded in `schema_migrations` and never delete existing data. Remedies are automatically seeded from `backend/data/remedies-catalog.json` on first use.

## Production checklist

- Use HTTPS and set `APP_URL` to the public origin.
- Replace the default admin credentials and use a restricted MySQL user.
- Configure live Razorpay keys and webhooks before accepting live payments.
- Set `PURCHASE_MAIL_TO=kubervastu153@gmail.com`. For the Support mailbox, set
  `SMTP_HOST=smtpout.secureserver.net`, `SMTP_PORT=465`, `SMTP_ENCRYPTION=ssl`,
  and `SMTP_USER`/`MAIL_FROM` to `Support@kubervastu.com`. Put the mailbox
  password in `SMTP_PASSWORD` in the server's private `.env` file. Verified
  paid orders trigger the email notification. The server falls back to PHP
  `mail()` if SMTP delivery fails.
- Back up MySQL and `public/uploads`.
