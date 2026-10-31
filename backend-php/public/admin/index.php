<?php
declare(strict_types=1);
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: SAMEORIGIN');
header('Referrer-Policy: same-origin');
header("Permissions-Policy: camera=(), microphone=(), geolocation=()");
?>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Kuber Vastu Admin</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f5eedd;
        --panel: #fffbf1;
        --panel-2: #f1e0be;
        --line: rgba(155, 116, 40, 0.24);
        --gold: #9b7428;
        --gold-2: #b8913e;
        --text: #2a2117;
        --muted: rgba(60, 48, 34, 0.68);
        --danger: #b42318;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        min-height: 100vh;
        background: linear-gradient(180deg, var(--bg), #fff8e9 55%, #ead9b8);
        color: var(--text);
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        line-height: 1.45;
      }

      .hidden {
        display: none !important;
      }

      .login-view {
        min-height: 100vh;
        display: grid;
        place-items: center;
        padding: 20px;
      }

      .login-card {
        width: min(420px, 100%);
        padding: 24px;
        border: 1px solid var(--line);
        border-radius: 14px;
        background: var(--panel);
        box-shadow: 0 24px 60px rgba(42, 33, 23, 0.16);
      }

      .login-mark {
        width: 58px;
        height: 58px;
        margin: 0 auto 14px;
        display: grid;
        place-items: center;
        border-radius: 14px;
        background: linear-gradient(135deg, var(--gold-2), var(--gold));
        color: white;
        font-size: 28px;
        font-weight: 900;
      }

      .login-card form {
        padding: 20px 0 0;
      }

      .login-error {
        min-height: 20px;
        color: var(--danger);
        font-size: 12px;
      }

      header {
        position: sticky;
        top: 0;
        z-index: 5;
        border-bottom: 1px solid var(--line);
        background: rgba(255, 251, 241, 0.94);
        backdrop-filter: blur(12px);
      }

      .bar,
      main {
        width: min(1180px, calc(100% - 28px));
        margin: 0 auto;
      }

      .bar {
        height: 64px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
      }

      h1,
      h2,
      h3,
      p {
        margin: 0;
      }

      h1 {
        font-size: 22px;
        font-weight: 800;
      }

      h2 {
        font-size: 17px;
        font-weight: 800;
      }

      h3 {
        font-size: 13px;
        color: var(--text);
        font-weight: 800;
      }

      button {
        border: 0;
        border-radius: 8px;
        padding: 9px 12px;
        background: var(--gold);
        color: var(--text);
        font-weight: 750;
        cursor: pointer;
        transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease;
      }

      button:hover {
        box-shadow: 0 8px 18px rgba(155, 116, 40, 0.18);
        transform: translateY(-1px);
      }

      button:active {
        transform: translateY(0);
      }

      button.secondary {
        border: 1px solid var(--line);
        background: rgba(255, 251, 241, 0.72);
        color: var(--text);
      }

      button.danger {
        background: rgba(180, 35, 24, 0.1);
        color: var(--danger);
        border: 1px solid rgba(180, 35, 24, 0.28);
      }

      main {
        padding: 22px 0 36px;
      }

      .status {
        min-height: 24px;
        margin-bottom: 12px;
        color: var(--muted);
        font-size: 13px;
      }

      .grid {
        display: grid;
        gap: 14px;
      }

      .stats {
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      }

      .stat,
      section,
      dialog {
        border: 1px solid var(--line);
        background: linear-gradient(180deg, var(--panel), rgba(241, 224, 190, 0.72));
        border-radius: 8px;
        box-shadow: 0 12px 28px rgba(42, 33, 23, 0.08);
      }

      .stat {
        padding: 16px;
        position: relative;
        overflow: hidden;
      }

      .stat::before {
        content: "";
        position: absolute;
        inset: 0 auto 0 0;
        width: 4px;
        background: var(--gold);
      }

      .stat span {
        display: block;
        color: var(--muted);
        font-size: 12px;
      }

      .stat strong {
        display: block;
        margin-top: 8px;
        font-size: 28px;
      }

      .layout {
        grid-template-columns: 1.05fr 0.95fr;
        margin-top: 16px;
      }

      section {
        overflow: hidden;
      }

      .section-head {
        min-height: 54px;
        padding: 14px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        border-bottom: 1px solid var(--line);
        background: rgba(255, 251, 241, 0.62);
      }

      .list {
        padding: 12px;
        display: grid;
        gap: 10px;
      }

      .item {
        border: 1px solid rgba(155, 116, 40, 0.16);
        border-radius: 8px;
        padding: 12px;
        background: rgba(255, 251, 241, 0.78);
        box-shadow: 0 8px 18px rgba(42, 33, 23, 0.05);
      }

      .item-head {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 12px;
      }

      .remedy-summary {
        display: flex;
        align-items: flex-start;
        gap: 12px;
        min-width: 0;
      }

      .remedy-image {
        width: 76px;
        height: 76px;
        flex: 0 0 76px;
        object-fit: contain;
        border: 1px solid rgba(155, 116, 40, 0.18);
        border-radius: 10px;
        background: #fff;
      }

      .muted {
        color: var(--muted);
        font-size: 12px;
        line-height: 1.45;
      }

      .actions {
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
      }

      table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
      }

      th,
      td {
        padding: 11px 12px;
        text-align: left;
        border-bottom: 1px solid rgba(155, 116, 40, 0.12);
        vertical-align: top;
      }

      th {
        color: var(--gold-2);
        font-size: 12px;
        font-weight: 800;
        background: rgba(241, 224, 190, 0.36);
      }

      tbody tr:hover {
        background: rgba(255, 251, 241, 0.74);
      }

      dialog {
        width: min(520px, calc(100% - 28px));
        color: var(--text);
        padding: 0;
      }

      dialog::backdrop {
        background: rgba(42, 33, 23, 0.38);
      }

      form {
        padding: 16px;
        display: grid;
        gap: 12px;
      }

      label {
        display: grid;
        gap: 6px;
        color: var(--muted);
        font-size: 12px;
      }

      label.check {
        display: flex;
        align-items: center;
        gap: 8px;
      }

      input,
      textarea,
      select {
        width: 100%;
        border: 1px solid var(--line);
        border-radius: 8px;
        background: var(--panel);
        color: var(--text);
        padding: 10px;
        font: inherit;
        outline: none;
        transition: border-color 160ms ease, box-shadow 160ms ease;
      }

      input:focus,
      textarea:focus,
      select:focus {
        border-color: var(--gold);
        box-shadow: 0 0 0 3px rgba(155, 116, 40, 0.12);
      }

      input[type="checkbox"] {
        width: 16px;
        height: 16px;
        accent-color: var(--gold);
      }

      textarea {
        min-height: 80px;
        resize: vertical;
      }

      .empty {
        padding: 16px;
        color: var(--muted);
        font-size: 13px;
      }

      @media (max-width: 820px) {
        .stats,
        .layout {
          grid-template-columns: 1fr;
        }

        .bar {
          height: auto;
          padding: 14px 0;
          align-items: flex-start;
          flex-direction: column;
        }
      }
    </style>
  </head>
  <body>
    <div id="loginView" class="login-view">
      <div class="login-card">
        <div class="login-mark">K</div>
        <h1 style="text-align: center">Kuber Vastu Admin</h1>
        <p class="muted" style="text-align: center; margin-top: 5px">Sign in to manage the application</p>
        <form id="loginForm">
          <label>
            Admin Email
            <input id="adminEmail" type="email" autocomplete="username" required />
          </label>
          <label>
            Password
            <input id="adminPassword" type="password" autocomplete="current-password" required />
          </label>
          <div id="loginError" class="login-error"></div>
          <button id="loginBtn" type="submit">Login to Dashboard</button>
        </form>
      </div>
    </div>

    <header id="adminHeader" class="hidden">
      <div class="bar">
        <div>
          <h1>Kuber Vastu Admin</h1>
          <p class="muted">Users, remedies, orders, and payments</p>
        </div>
        <div class="actions">
          <button id="refreshBtn" type="button">Refresh</button>
          <button id="logoutBtn" class="secondary" type="button">Logout</button>
        </div>
      </div>
    </header>

    <main id="dashboard" class="hidden">
      <div id="status" class="status">Loading admin data...</div>
      <div class="grid stats" id="stats"></div>

      <section style="margin-top: 16px">
        <div class="section-head">
          <h2>App Update</h2>
        </div>
        <form id="updateForm">
          <label class="check">
            <input id="updateEnabled" type="checkbox" />
            Enable update check
          </label>
          <div class="grid layout" style="margin-top: 0">
            <label>
              Latest Version
              <input id="latestVersion" placeholder="1.0.1" required />
            </label>
            <label>
              Latest Build Number
              <input id="latestBuildNumber" type="number" min="1" placeholder="2" required />
            </label>
          </div>
          <label>
            APK / Play Store Download Link
            <input id="downloadUrl" placeholder="https://example.com/kubar-vastu.apk" />
          </label>
          <label>
            Update Message
            <textarea id="releaseNotes" placeholder="Write what is new in this version"></textarea>
          </label>
          <label class="check">
            <input id="forceUpdate" type="checkbox" />
            Force users to update before continuing
          </label>
          <div class="actions" style="justify-content: flex-end">
            <button type="submit">Save Update Settings</button>
          </div>
        </form>
      </section>

      <div class="grid layout">
        <section>
          <div class="section-head">
            <h2>Remedies</h2>
            <button id="addRemedyBtn" type="button">Add Remedy</button>
          </div>
          <div class="list" id="remedies"></div>
        </section>

        <section>
          <div class="section-head">
            <h2>Registered Users</h2>
          </div>
          <div class="list" id="users"></div>
        </section>
      </div>

      <section style="margin-top: 16px">
        <div class="section-head">
          <div>
            <h2>YouTube Videos</h2>
            <p class="muted">Videos published here appear in Discover - Videos.</p>
          </div>
          <button id="addVideoBtn" type="button">Add YouTube Video</button>
        </div>
        <div class="list" id="videos"></div>
      </section>

      <div class="grid layout">
        <section>
          <div class="section-head">
            <h2>Blog Posts</h2>
            <button id="addBlogBtn" type="button">Add Blog</button>
          </div>
          <div class="list" id="blogs"></div>
        </section>

        <section>
          <div class="section-head">
            <div>
              <h2>User Reviews</h2>
              <p class="muted">Approve reviews before they appear in the app.</p>
            </div>
          </div>
          <div class="list" id="reviews"></div>
        </section>
      </div>

      <section style="margin-top: 16px">
        <div class="section-head">
          <h2>Payment History</h2>
        </div>
        <div style="overflow-x: auto">
          <table>
            <thead>
              <tr>
                <th>Remedy</th>
                <th>Qty</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Shipping details</th>
                <th>Valid Until</th>
                <th>Purchased</th>
              </tr>
            </thead>
            <tbody id="orders"></tbody>
          </table>
        </div>
      </section>
    </main>

    <dialog id="remedyDialog">
      <form id="remedyForm" method="dialog">
        <h2 id="dialogTitle">Add Remedy</h2>
        <input id="remedyId" type="hidden" />
        <label>
          Title
          <input id="title" required />
        </label>
        <label>
          Subtitle
          <input id="subtitle" />
        </label>
        <label>
          Direction
          <input id="direction" required />
        </label>
          <label>
            Purpose
            <textarea id="purpose" required></textarea>
          </label>
          <label>Why You Need It<textarea id="whyYouNeed"></textarea></label>
          <label>How It Works<textarea id="howItWorks"></textarea></label>
          <label>What You Get<textarea id="whatYouGet"></textarea></label>
          <label>Where To Place It<textarea id="placement"></textarea></label>
          <label>Offers (one per line)<textarea id="offers"></textarea></label>
          <label>
            Category
            <select id="category" required>
              <option>Wealth &amp; Prosperity</option>
              <option>Health &amp; Energy</option>
              <option>Relationships &amp; Harmony</option>
              <option>Clarity &amp; Spiritual Growth</option>
              <option>Figurines Collection</option>
              <option>Vastu Remedies Collection</option>
              <option>General Remedies</option>
            </select>
          </label>
        <label>
          Price
          <input id="price" type="number" min="0" required />
        </label>
        <label>
          Product Photos (up to 10 URLs, one per line)
          <textarea id="imageUrls" placeholder="https://example.com/product-photo.jpg"></textarea>
        </label>
        <label>Upload Product Photos (PNG, JPG, WEBP; max 8 MB each)<input id="imageFiles" type="file" accept="image/png,image/jpeg,image/webp" multiple /></label>
        <label>
          Product Videos (up to 6 URLs, one per line)
          <textarea id="videoUrls" placeholder="https://youtube.com/watch?v=..."></textarea>
        </label>
        <label>Upload Product Videos (MP4, WEBM; max 8 MB each)<input id="videoFiles" type="file" accept="video/mp4,video/webm" multiple /></label>
        <label>Installation Photos (URLs, one per line)<textarea id="installationImageUrls"></textarea></label>
        <label>Upload Installation Photos<input id="installationImageFiles" type="file" accept="image/png,image/jpeg,image/webp" multiple /></label>
        <label>Installation Videos (URLs, one per line)<textarea id="installationVideoUrls"></textarea></label>
        <label>Upload Installation Videos<input id="installationVideoFiles" type="file" accept="video/mp4,video/webm" multiple /></label>
        <div class="actions" style="justify-content: flex-end">
          <button class="secondary" value="cancel" type="button" id="cancelBtn">Cancel</button>
          <button value="default" type="submit">Save</button>
        </div>
      </form>
    </dialog>

    <dialog id="blogDialog">
      <form id="blogForm" method="dialog">
        <h2 id="blogDialogTitle">Add Blog</h2>
        <input id="blogId" type="hidden" />
        <label>
          Blog Title
          <input id="blogTitle" required maxlength="180" />
        </label>
        <label>
          Short Description
          <textarea id="blogDescription" required maxlength="500"></textarea>
        </label>
        <label>
          Full Blog Content
          <textarea id="blogContent" required style="min-height: 180px"></textarea>
        </label>
        <label>
          Cover Image URL
          <input id="blogImageUrl" type="url" placeholder="https://example.com/image.jpg" />
        </label>
        <label>
          Category
          <input id="blogCategory" value="Vastu" required />
        </label>
        <label class="check">
          <input id="blogPublished" type="checkbox" checked />
          Publish immediately
        </label>
        <div class="actions" style="justify-content: flex-end">
          <button class="secondary" type="button" id="cancelBlogBtn">Cancel</button>
          <button type="submit">Save Blog</button>
        </div>
      </form>
    </dialog>

    <dialog id="videoDialog">
      <form id="videoForm" method="dialog">
        <h2 id="videoDialogTitle">Add YouTube Video</h2>
        <input id="videoRecordId" type="hidden" />
        <label>
          YouTube Video URL
          <input id="youtubeUrl" type="url" placeholder="https://www.youtube.com/watch?v=..." required />
        </label>
        <label>
          Video Title
          <input id="videoTitle" required maxlength="180" />
        </label>
        <label>
          Custom Thumbnail URL (optional)
          <input id="videoThumbnail" type="url" placeholder="Uses YouTube thumbnail automatically" />
        </label>
        <label class="check">
          <input id="videoPublished" type="checkbox" checked />
          Show in Discover
        </label>
        <div class="actions" style="justify-content: flex-end">
          <button class="secondary" type="button" id="cancelVideoBtn">Cancel</button>
          <button type="submit">Save Video</button>
        </div>
      </form>
    </dialog>

    <script>
      const state = { overview: null };
      const loginView = document.querySelector("#loginView");
      const adminHeader = document.querySelector("#adminHeader");
      const dashboard = document.querySelector("#dashboard");
      const loginForm = document.querySelector("#loginForm");
      const loginError = document.querySelector("#loginError");
      const statusEl = document.querySelector("#status");
      const statsEl = document.querySelector("#stats");
      const remediesEl = document.querySelector("#remedies");
      const usersEl = document.querySelector("#users");
      const ordersEl = document.querySelector("#orders");
      const blogsEl = document.querySelector("#blogs");
      const reviewsEl = document.querySelector("#reviews");
      const videosEl = document.querySelector("#videos");
      const updateForm = document.querySelector("#updateForm");
      const dialog = document.querySelector("#remedyDialog");
      const form = document.querySelector("#remedyForm");
      const blogDialog = document.querySelector("#blogDialog");
      const blogForm = document.querySelector("#blogForm");
      const videoDialog = document.querySelector("#videoDialog");
      const videoForm = document.querySelector("#videoForm");

      document.querySelector("#refreshBtn").addEventListener("click", load);
      document.querySelector("#logoutBtn").addEventListener("click", logout);
      document.querySelector("#addRemedyBtn").addEventListener("click", () => openRemedy());
      document.querySelector("#cancelBtn").addEventListener("click", () => dialog.close());
      document.querySelector("#addBlogBtn").addEventListener("click", () => openBlog());
      document.querySelector("#cancelBlogBtn").addEventListener("click", () => blogDialog.close());
      document.querySelector("#addVideoBtn").addEventListener("click", () => openVideo());
      document.querySelector("#cancelVideoBtn").addEventListener("click", () => videoDialog.close());

      loginForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        loginError.textContent = "";
        const button = document.querySelector("#loginBtn");
        button.disabled = true;
        button.textContent = "Signing in...";
        try {
          await request("/api/admin/login", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              email: document.querySelector("#adminEmail").value.trim(),
              password: document.querySelector("#adminPassword").value,
            }),
          });
          showDashboard();
          await load();
        } catch (error) {
          loginError.textContent = error.message;
        } finally {
          button.disabled = false;
          button.textContent = "Login to Dashboard";
        }
      });

      updateForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const payload = {
          enabled: document.querySelector("#updateEnabled").checked,
          latestVersion: document.querySelector("#latestVersion").value.trim(),
          latestBuildNumber: Number(document.querySelector("#latestBuildNumber").value || 1),
          downloadUrl: document.querySelector("#downloadUrl").value.trim(),
          releaseNotes: document.querySelector("#releaseNotes").value.trim(),
          forceUpdate: document.querySelector("#forceUpdate").checked,
        };
        await request("/api/admin/app-update", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        await load();
      });

      form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const id = document.querySelector("#remedyId").value.trim();
        const uploadFiles = async (inputId) => {
          const urls = [];
          for (const file of Array.from(document.querySelector(inputId).files || [])) {
            const data = await new Promise((resolve, reject) => {
              const reader = new FileReader();
              reader.onload = () => resolve(reader.result);
              reader.onerror = reject;
              reader.readAsDataURL(file);
            });
            const uploaded = await request("/api/admin/uploads", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ data }),
            });
            urls.push(uploaded.url);
          }
          return urls;
        };
        const productUploads = await uploadFiles("#imageFiles");
        const videoUploads = await uploadFiles("#videoFiles");
        const installationImageUploads = await uploadFiles("#installationImageFiles");
        const installationVideoUploads = await uploadFiles("#installationVideoFiles");
        const lines = (selector, limit) => document.querySelector(selector).value.split(/\n/).map(value => value.trim()).filter(Boolean).slice(0, limit);
        const payload = {
          title: document.querySelector("#title").value.trim(),
          subtitle: document.querySelector("#subtitle").value.trim(),
          direction: document.querySelector("#direction").value.trim(),
            purpose: document.querySelector("#purpose").value.trim(),
            category: document.querySelector("#category").value,
          price: Number(document.querySelector("#price").value || 0),
          whyYouNeed: document.querySelector("#whyYouNeed").value.trim(),
          howItWorks: document.querySelector("#howItWorks").value.trim(),
          whatYouGet: document.querySelector("#whatYouGet").value.trim(),
          placement: document.querySelector("#placement").value.trim(),
          offers: lines("#offers", 8),
          imageUrls: [...lines("#imageUrls", 10), ...productUploads].slice(0, 10),
          videoUrls: [...lines("#videoUrls", 6), ...videoUploads].slice(0, 6),
          installationImageUrls: [...lines("#installationImageUrls", 10), ...installationImageUploads].slice(0, 10),
          installationVideoUrls: [...lines("#installationVideoUrls", 6), ...installationVideoUploads].slice(0, 6),
        };
        await request(
          id ? `/api/admin/remedies/${encodeURIComponent(id)}` : "/api/admin/remedies",
          {
            method: id ? "PUT" : "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload),
          },
        );
        dialog.close();
        await load();
      });

      blogForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const id = document.querySelector("#blogId").value.trim();
        const payload = {
          title: document.querySelector("#blogTitle").value.trim(),
          description: document.querySelector("#blogDescription").value.trim(),
          content: document.querySelector("#blogContent").value.trim(),
          imageUrl: document.querySelector("#blogImageUrl").value.trim(),
          category: document.querySelector("#blogCategory").value.trim() || "Vastu",
          published: document.querySelector("#blogPublished").checked,
        };
        await request(id ? `/api/admin/blogs/${encodeURIComponent(id)}` : "/api/admin/blogs", {
          method: id ? "PUT" : "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        blogDialog.close();
        await load();
      });

      videoForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const id = document.querySelector("#videoRecordId").value.trim();
        const payload = {
          youtubeUrl: document.querySelector("#youtubeUrl").value.trim(),
          title: document.querySelector("#videoTitle").value.trim(),
          thumbnailUrl: document.querySelector("#videoThumbnail").value.trim(),
          published: document.querySelector("#videoPublished").checked,
        };
        await request(id ? `/api/admin/videos/${encodeURIComponent(id)}` : "/api/admin/videos", {
          method: id ? "PUT" : "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        videoDialog.close();
        await load();
      });

      const portalBasePath = window.location.pathname.replace(/\/admin(?:\/index\.php)?\/?$/, "");

      async function request(path, options) {
        const requestUrl = path.startsWith("/") ? `${portalBasePath}${path}` : path;
        const response = await fetch(requestUrl, { credentials: "same-origin", ...(options || {}) });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(data.error || "Request failed");
        return data;
      }

      async function load() {
        try {
          statusEl.textContent = "Loading admin data...";
          state.overview = await request("/api/admin/overview");
          render();
          statusEl.textContent = "Admin data loaded.";
        } catch (error) {
          statusEl.textContent = `Error: ${error.message}`;
        }
      }

      function showDashboard() {
        loginView.classList.add("hidden");
        adminHeader.classList.remove("hidden");
        dashboard.classList.remove("hidden");
      }

      function showLogin() {
        dashboard.classList.add("hidden");
        adminHeader.classList.add("hidden");
        loginView.classList.remove("hidden");
        document.querySelector("#adminPassword").value = "";
      }

      async function logout() {
        try {
          await request("/api/admin/logout", { method: "POST" });
        } finally {
          state.overview = null;
          showLogin();
        }
      }

      async function initialize() {
        try {
          await request("/api/admin/session");
          showDashboard();
          await load();
        } catch (_) {
          showLogin();
        }
      }

      function render() {
        const data = state.overview || {};
        const stats = data.stats || {};
        renderAppUpdate(data.appUpdate || {});
        statsEl.innerHTML = [
          ["Users", stats.users || 0],
          ["Remedies", stats.remedies || 0],
          ["Orders", stats.orders || 0],
          ["Payments", `Rs ${stats.paymentsTotal || 0}`],
          ["Blogs", stats.blogs || 0],
          ["Pending Reviews", stats.pendingReviews || 0],
          ["Videos", stats.videos || 0],
        ]
          .map(([label, value]) => `<div class="stat"><span>${label}</span><strong>${value}</strong></div>`)
          .join("");

        remediesEl.innerHTML = (data.remedies || []).length
          ? data.remedies.map(remedyCard).join("")
          : `<div class="empty">No remedies yet.</div>`;

        usersEl.innerHTML = (data.users || []).length
          ? data.users.map(userCard).join("")
          : `<div class="empty">No users yet.</div>`;

        ordersEl.innerHTML = (data.orders || []).length
          ? data.orders.map(orderRow).join("")
          : `<tr><td colspan="7" class="empty">No payment history yet.</td></tr>`;

        blogsEl.innerHTML = (data.blogs || []).length
          ? data.blogs.map(blogCard).join("")
          : `<div class="empty">No blog posts yet.</div>`;

        reviewsEl.innerHTML = (data.testimonials || []).length
          ? data.testimonials.map(reviewCard).join("")
          : `<div class="empty">No user reviews yet.</div>`;

        videosEl.innerHTML = (data.videos || []).length
          ? data.videos.map(videoCard).join("")
          : `<div class="empty">No admin YouTube videos yet. Add one using its YouTube link.</div>`;

        document.querySelectorAll("[data-edit]").forEach((button) => {
          button.addEventListener("click", () => {
            const remedy = (state.overview.remedies || []).find((item) => item.id === button.dataset.edit);
            openRemedy(remedy);
          });
        });

        document.querySelectorAll("[data-delete]").forEach((button) => {
          button.addEventListener("click", async () => {
            if (!confirm("Delete this remedy?")) return;
            await request(`/api/admin/remedies/${encodeURIComponent(button.dataset.delete)}`, {
              method: "DELETE",
            });
            await load();
          });
        });

        document.querySelectorAll("[data-edit-blog]").forEach((button) => {
          button.addEventListener("click", () => {
            const blog = (state.overview.blogs || []).find((item) => item.id === button.dataset.editBlog);
            openBlog(blog);
          });
        });

        document.querySelectorAll("[data-delete-blog]").forEach((button) => {
          button.addEventListener("click", async () => {
            if (!confirm("Delete this blog post?")) return;
            await request(`/api/admin/blogs/${encodeURIComponent(button.dataset.deleteBlog)}`, { method: "DELETE" });
            await load();
          });
        });

        document.querySelectorAll("[data-review-status]").forEach((button) => {
          button.addEventListener("click", async () => {
            await request(`/api/admin/testimonials/${encodeURIComponent(button.dataset.reviewId)}/status`, {
              method: "PUT",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ status: button.dataset.reviewStatus }),
            });
            await load();
          });
        });

        document.querySelectorAll("[data-edit-video]").forEach((button) => {
          button.addEventListener("click", () => {
            const video = (state.overview.videos || []).find((item) => item.recordId === button.dataset.editVideo);
            openVideo(video);
          });
        });

        document.querySelectorAll("[data-delete-video]").forEach((button) => {
          button.addEventListener("click", async () => {
            if (!confirm("Delete this YouTube video?")) return;
            await request(`/api/admin/videos/${encodeURIComponent(button.dataset.deleteVideo)}`, { method: "DELETE" });
            await load();
          });
        });
      }

      function renderAppUpdate(update) {
        document.querySelector("#updateEnabled").checked = update.enabled !== false;
        document.querySelector("#latestVersion").value = update.latestVersion || "1.0.0";
        document.querySelector("#latestBuildNumber").value = update.latestBuildNumber || 1;
        document.querySelector("#downloadUrl").value = update.downloadUrl || "";
        document.querySelector("#releaseNotes").value = update.releaseNotes || "";
        document.querySelector("#forceUpdate").checked = Boolean(update.forceUpdate);
      }

      function remedyCard(remedy) {
        const imageUrl = Array.isArray(remedy.imageUrls) ? remedy.imageUrls.find(Boolean) : "";
        return `
          <article class="item">
            <div class="item-head">
              <div class="remedy-summary">
                ${imageUrl ? `<img class="remedy-image" src="${escapeAttr(imageUrl)}" alt="${escapeAttr(remedy.title || "Remedy")}" loading="lazy" onerror="this.style.display='none'">` : ""}
                <div>
                  <h3>${escapeHtml(remedy.title)}</h3>
                  <p class="muted">${escapeHtml(remedy.category || "General Remedies")} | ${escapeHtml(remedy.direction)} - Rs ${Number(remedy.price || 0)}</p>
                  <p class="muted">${escapeHtml(remedy.purpose || "")}</p>
                </div>
              </div>
              <div class="actions">
                <button class="secondary" type="button" data-edit="${escapeAttr(remedy.id)}">Edit</button>
                <button class="danger" type="button" data-delete="${escapeAttr(remedy.id)}">Delete</button>
              </div>
            </div>
          </article>
        `;
      }

      function userCard(user) {
        return `
          <article class="item">
            <h3>${escapeHtml(user.name || "User")}</h3>
            <p class="muted">Username: ${escapeHtml(user.username || "-")}</p>
            <p class="muted">Gender: ${escapeHtml(user.gender || "-")}</p>
            <p class="muted">Mobile: ${escapeHtml(user.phone || "-")}</p>
            <p class="muted">Mail ID: ${escapeHtml(user.email || "-")}</p>
            <p class="muted">Place: ${escapeHtml(user.place || "-")}</p>
            <p class="muted">Type: ${escapeHtml(user.userType || "-")}</p>
            <p class="muted">Registered: ${formatDate(user.createdAt)}</p>
            <p class="muted">Last login: ${formatDate(user.lastLoginAt)}</p>
          </article>
        `;
      }

      function orderRow(order) {
        return `
          <tr>
            <td>${escapeHtml(order.remedyName || "Remedy")}</td>
            <td>${Number(order.quantity || 1)}</td>
            <td>Rs ${Number(order.price || 0)}</td>
            <td>${escapeHtml(order.status || "created")}</td>
            <td>${order.shipping ? [
              order.shipping.name,
              order.shipping.phone,
              order.shipping.address,
              order.shipping.city,
              order.shipping.state,
              order.shipping.pincode
            ].map(value => escapeHtml(value || "")).join("<br>") : "-"}</td>
            <td>${formatDate(order.validityEndsAt)}</td>
            <td>${formatDate(order.purchasedAt)}</td>
          </tr>
        `;
      }

      function blogCard(blog) {
        return `
          <article class="item">
            <div class="item-head">
              <div>
                <h3>${escapeHtml(blog.title)}</h3>
                <p class="muted">${escapeHtml(blog.category || "Vastu")} | ${blog.published ? "Published" : "Draft"}</p>
                <p class="muted">${escapeHtml(blog.description || "")}</p>
                <p class="muted">${formatDate(blog.publishedAt)}</p>
              </div>
              <div class="actions">
                <button class="secondary" type="button" data-edit-blog="${escapeAttr(blog.id)}">Edit</button>
                <button class="danger" type="button" data-delete-blog="${escapeAttr(blog.id)}">Delete</button>
              </div>
            </div>
          </article>
        `;
      }

      function reviewCard(review) {
        const stars = "★".repeat(Math.max(1, Math.min(5, Number(review.rating || 5))));
        return `
          <article class="item">
            <div class="item-head">
              <div>
                <h3>${escapeHtml(review.name || "User")} - ${escapeHtml(stars)}</h3>
                <p class="muted">Status: ${escapeHtml(review.status || "pending")} | ${formatDate(review.createdAt)}</p>
                <p style="margin-top: 8px">${escapeHtml(review.review || "")}</p>
              </div>
            </div>
            <div class="actions" style="margin-top: 10px">
              <button type="button" data-review-id="${escapeAttr(review.id)}" data-review-status="approved">Approve</button>
              <button class="secondary" type="button" data-review-id="${escapeAttr(review.id)}" data-review-status="pending">Pending</button>
              <button class="danger" type="button" data-review-id="${escapeAttr(review.id)}" data-review-status="rejected">Reject</button>
            </div>
          </article>
        `;
      }

      function videoCard(video) {
        return `
          <article class="item">
            <div class="item-head">
              <div>
                <h3>${escapeHtml(video.title || "YouTube Video")}</h3>
                <p class="muted">YouTube ID: ${escapeHtml(video.id || "-")} | ${video.published ? "Visible" : "Hidden"}</p>
                <a class="muted" href="https://www.youtube.com/watch?v=${escapeAttr(video.id)}" target="_blank" rel="noopener">Open on YouTube</a>
              </div>
              <div class="actions">
                <button class="secondary" type="button" data-edit-video="${escapeAttr(video.recordId)}">Edit</button>
                <button class="danger" type="button" data-delete-video="${escapeAttr(video.recordId)}">Delete</button>
              </div>
            </div>
          </article>
        `;
      }

      function openRemedy(remedy = null) {
        document.querySelector("#dialogTitle").textContent = remedy ? "Update Remedy" : "Add Remedy";
        document.querySelector("#remedyId").value = remedy?.id || "";
        document.querySelector("#title").value = remedy?.title || "";
        document.querySelector("#subtitle").value = remedy?.subtitle || "";
        document.querySelector("#direction").value = remedy?.direction || "";
        document.querySelector("#purpose").value = remedy?.purpose || "";
        document.querySelector("#whyYouNeed").value = remedy?.whyYouNeed || "";
        document.querySelector("#howItWorks").value = remedy?.howItWorks || "";
        document.querySelector("#whatYouGet").value = remedy?.whatYouGet || "";
        document.querySelector("#placement").value = remedy?.placement || remedy?.direction || "";
        document.querySelector("#offers").value = (remedy?.offers || []).join("\n");
        document.querySelector("#category").value = remedy?.category || "General Remedies";
        document.querySelector("#price").value = remedy?.price || 0;
        document.querySelector("#imageUrls").value = (remedy?.imageUrls || []).join("\n");
        document.querySelector("#videoUrls").value = (remedy?.videoUrls || []).join("\n");
        document.querySelector("#installationImageUrls").value = (remedy?.installationImageUrls || []).join("\n");
        document.querySelector("#installationVideoUrls").value = (remedy?.installationVideoUrls || []).join("\n");
        for (const id of ["imageFiles", "videoFiles", "installationImageFiles", "installationVideoFiles"]) document.querySelector(`#${id}`).value = "";
        dialog.showModal();
      }

      function openBlog(blog = null) {
        document.querySelector("#blogDialogTitle").textContent = blog ? "Update Blog" : "Add Blog";
        document.querySelector("#blogId").value = blog?.id || "";
        document.querySelector("#blogTitle").value = blog?.title || "";
        document.querySelector("#blogDescription").value = blog?.description || "";
        document.querySelector("#blogContent").value = blog?.content || "";
        document.querySelector("#blogImageUrl").value = blog?.imageUrl || "";
        document.querySelector("#blogCategory").value = blog?.category || "Vastu";
        document.querySelector("#blogPublished").checked = blog?.published !== false;
        blogDialog.showModal();
      }

      function openVideo(video = null) {
        document.querySelector("#videoDialogTitle").textContent = video ? "Update YouTube Video" : "Add YouTube Video";
        document.querySelector("#videoRecordId").value = video?.recordId || "";
        document.querySelector("#youtubeUrl").value = video?.id ? `https://www.youtube.com/watch?v=${video.id}` : "";
        document.querySelector("#videoTitle").value = video?.title || "";
        document.querySelector("#videoThumbnail").value = video?.thumbnailUrl || "";
        document.querySelector("#videoPublished").checked = video?.published !== false;
        videoDialog.showModal();
      }

      function formatDate(value) {
        if (!value) return "-";
        return new Intl.DateTimeFormat(undefined, {
          dateStyle: "medium",
          timeStyle: "short",
        }).format(new Date(value));
      }

      function escapeHtml(value) {
        return String(value).replace(/[&<>"']/g, (char) => ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#039;",
        })[char]);
      }

      function escapeAttr(value) {
        return escapeHtml(value).replace(/`/g, "&#096;");
      }

      initialize();
    </script>
  </body>
</html>
