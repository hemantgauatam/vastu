# App Review update — deployment and submission

## Changes
- Profile > Delete account: password-confirmed permanent deletion, with errors shown without logging the user out.
- PHP/MySQL and Node/MongoDB APIs: authenticated DELETE /api/me removes the account, sessions, linked orders/purchases, linked reviews and reports. Payment-provider records and previously sent emails are outside the app database and are not erased by this endpoint.
- Reviews require login and agreement to the content rules. New reviews have a stable contributor identity; legacy anonymous reviews cannot safely be attributed to an account.
- Discover > Reviews > review options: Report review submits a reason, hides it locally, and returns it to pending moderation on the server. Block contributor persistently hides that contributor's reviews on this device. Older anonymous reviews offer Hide review only. Blocking is device-local, not synced between devices.
- PHP admin User Reviews displays report reasons. Approve/Reject controls remain available. Review reported content promptly; establish a moderation response process before release.

## Deploy before distributing the new app
1. Back up the production database and deploy backend-php/src/App.php and backend-php/public/admin/index.php together. Keep existing production credentials; no credentials are included in this package.
2. Leave AUTO_MIGRATE=true for the first request. Migration 003_review_safety adds testimonials.user_id and content_reports without deleting existing rows. Back up first and verify on staging. Set a persistent APP_KEY environment value before release; changing it later changes contributor identifiers.
3. If using the alternative Node server, deploy backend/server.js. Its account deletion uses MongoDB transactions and requires a replica set or managed cluster with transaction support. It fails without deleting data on a standalone MongoDB instance.
4. Deploy the backend before the Flutter app. Previously anonymous reviews remain moderated content; manually remove any legacy reviews that need removal because ownership cannot be proven by their display names.
5. Build and test the iOS release on a Mac with Xcode. Increase version/build as required by App Store Connect. This source package is not a signed IPA.

## Physical-device QA and recording
Record the actual submitted build on a physical iPhone/iPad running the latest OS available for the review. Start from launching the app.
- Register a temporary account, log out, and log in again. Test wrong passwords and loss of internet.
- Open compass/chakras; verify readings and calibration. Test camera permission allow/deny and floor-plan import, alignment, overlays and export.
- Open Discover videos, blogs and reviews. Log in before writing a review; agree to the rules. Verify it stays pending until approved.
- Approve a test review in admin, report it from a second test account, and confirm the reason reaches admin and the review returns to pending.
- Publish two reviews from one test contributor and one from another. Block the first contributor and restart; only their reviews should remain hidden. Verify a legacy review offers Hide review rather than claiming to block its author.
- Test remedy checkout and order confirmation with appropriate test settings. Confirm whether all items are shipped physical goods, digital content or a mixture. Razorpay has not been replaced by Apple In-App Purchase. If digital purchases require StoreKit for your storefront/business model, complete that work before submission.
- Delete the temporary account from Profile, verify wrong-password failure, then successful deletion. Confirm login fails afterward and sessions and linked database records are removed. Keep the review demo account active.
- Test every supported iPhone/iPad platform and attach actual in-app screenshots.

Local PHP/MySQL integration checks passed for authentication, wrong-password protection, authenticated reviews, reports, moderation reasons, account deletion, session invalidation and linked review removal. No physical-device test, screen recording, signed iOS build or production deployment was performed.

## App Store Connect Notes — fill every bracket before submitting
1. Recording: [accessible URL]. Device: [model]. OS: [version]. App version/build: [version]. Recording begins at app launch and demonstrates the above features, including registration, login, account deletion and purchase access.
2. Purpose/audience: Kuber Vastu provides traditional Vastu Shastra directional information, compass/chakra visualization, floor-plan overlays, educational content and remedy listings for homeowners and Vastu practitioners.
3. Access: Demo username [username], password [password]. Log in through Profile. Open Map to import a sample plan [attach sample]. Access compass/chakras and camera tools through the navigation. Discover contains videos, articles and moderated reviews. Profile > Delete account permanently removes the logged-in account after password confirmation; use a separate temporary account to test this. Purchase testing: [exact instructions].
4. External services: custom account/content/order backend at admin.kubervastu.com; MySQL (PHP deployment) or MongoDB (alternative Node deployment); YouTube video playback/Data API when configured; Razorpay checkout; Google Fonts; [confirm deployed SMTP/email provider and any other active services].
5. Regions: [confirm app feature/content consistency, and specify shipping destinations, INR/payment availability, languages and any regional restrictions].
6. Authorizations: [confirm applicable industry authorizations and ownership/licensing of articles, video, images, testimonials and other third-party materials; attach evidence where needed].

Do not describe the build as fully tested or approved until those steps are complete. Account deletion deletes app database order and purchase records; confirm this behavior is appropriate for your operational and recordkeeping needs before deployment.


## Try the updates locally
Run `powershell -ExecutionPolicy Bypass -File scripts/start-review-preview.ps1` from the project folder. XAMPP PHP/MariaDB and Flutter must be installed. The launcher uses a separate database under `.review-preview/mysql`, binds the backend to 127.0.0.1:4001 and serves the app at http://localhost:8081. Keep the launcher running while testing. The database process remains running for reuse.

- Profile login: `reviewdemo` / `LocalReview2026!`.
- Local admin: http://127.0.0.1:4001/admin/ — `review-admin@example.com` / `LocalReviewAdmin2026!`.
- Open Discover > Reviews and use the three-dot menu on a LOCAL DEMO review. Two sample reviews share Contributor A, so blocking A should hide both.
- Report a review with a reason, then check User Reviews in the local admin portal.
- Profile > Delete account tests deletion. You can register your own temporary account or delete the local demo account; restarting the launcher recreates missing demo accounts.
- Run `python scripts/check-review-preview.py` while the preview is running to repeat backend integration checks. It creates and removes temporary QA accounts.

These credentials belong only to the isolated local preview. Payment/email/API credentials from the existing .env are disabled for the preview. The browser preview cannot verify the physical iPhone compass, camera behavior or App Store build.
