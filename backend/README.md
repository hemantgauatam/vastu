# Kubar Vastu Backend

Separate Node.js + MongoDB API for user accounts, login/logout sessions, remedies,
orders, in-app update settings, and admin overview data.

## Dynamic content

Set `YOUTUBE_API_KEY` and `YOUTUBE_CHANNEL_ID` in the server environment to
serve the latest channel uploads. Never place the YouTube API key in Flutter
source or client-side build variables.

- `GET /api/content/videos`
- `GET /api/blogs?page=1&limit=8&q=vastu`
- `POST /api/admin/blogs`
- `GET /api/testimonials` (approved only)
- `POST /api/testimonials` (creates pending feedback)
- `PUT /api/admin/testimonials/:id/status`

## Setup

```bash
cd backend
npm install
```

For the included local Windows MongoDB installation, start the persistent
database and API together from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File backend\start-local.ps1
```

Database files are stored in `backend/data/mongodb/`. The script seeds the
default remedies automatically and keeps the API available on port `4000`.

Start MongoDB locally, or set `MONGODB_URI` for your hosted database.

```bash
set MONGODB_URI=mongodb://127.0.0.1:27017/divinewall
set PORT=4000
set RAZORPAY_KEY_ID=rzp_test_your_key_id
set RAZORPAY_KEY_SECRET=your_test_key_secret
npm start
```

Razorpay orders are created server-side. Payment signatures are verified by the
backend before purchases are marked paid. A verified remedy purchase receives
one year of validity. Use HTTPS and Razorpay webhooks before switching to live
keys.

Successful purchases send an order notification to `PURCHASE_MAIL_TO` (defaults
to `Kubervastu153@gmail.com`). Enable delivery with a Gmail account that has
2-Step Verification and an App Password, then configure:

```bash
set PURCHASE_MAIL_TO=Kubervastu153@gmail.com
set GMAIL_USER=your-sender@gmail.com
set GMAIL_APP_PASSWORD=your_16_character_app_password
```

Never use the Gmail account's normal password or commit the App Password.

The app already opens the hosted Razorpay Checkout page from the cart, verifies
the payment signature on the server, records the purchase, and refreshes the
user's active remedies. Copy `backend/.env.example` values into your deployment
environment and replace the test placeholders with credentials from Razorpay.

Run the Flutter app against the backend:

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:4000
```

For an Android emulator use `http://10.0.2.2:4000`. On a physical phone,
use the computer's LAN address, for example `http://192.168.1.10:4000`.

Open the separate admin web app:

```text
http://localhost:4000/admin
```

Admin login (configure the password privately first):

```text
Email: admin@gmail.com
Password: set ADMIN_PASSWORD privately
```

For production, override both defaults before starting the server:

```bash
set ADMIN_EMAIL=your-admin@example.com
set ADMIN_PASSWORD=<your-private-password>
set ADMIN_SESSION_HOURS=12
```

Use the **App Update** section in the admin panel to set:

- latest app version, for example `1.0.1`
- latest build number, for example `2`
- APK or Play Store download link
- update message / release notes
- force update on or off

## Main Endpoints

- `GET /health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/me`
- `GET /api/remedies`
- `GET /api/app-update`
- `POST /api/orders`
- `GET /api/admin/overview`
- `GET /api/admin/app-update`
- `PUT /api/admin/app-update`
- `POST /api/admin/remedies`
- `PUT /api/admin/remedies/:id`
- `DELETE /api/admin/remedies/:id`

Authenticated endpoints use:

```text
Authorization: Bearer <token>
```

## Example Requests

Register:

```bash
curl -X POST http://localhost:4000/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Demo User\",\"gender\":\"Male\",\"email\":\"demo@example.com\",\"phone\":\"9999999999\",\"place\":\"Jaipur\",\"userType\":\"Customer\",\"username\":\"demo\",\"password\":\"secret123\"}"
```

Login:

```bash
curl -X POST http://localhost:4000/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"demo\",\"password\":\"secret123\"}"
```

Create an order:

```bash
curl -X POST http://localhost:4000/api/orders ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer <token>" ^
  -d "{\"remedyId\":\"wealth-kalash\"}"
```
