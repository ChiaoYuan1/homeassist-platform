import {
  getPendingProviders,
  getAdminProviders,
  getAdminActiveBookingCount,
} from '../../services/admin-service.js';

function showAdminDashboardPage(
  app,
  {
    adminName,
    onSignOut,
    onProviderApplications,
    onAdminReports,
    onProviderManagement,
  },
) {
  app.innerHTML = `
    <main class="admin-layout">
      <aside class="admin-sidebar">
        <div class="admin-brand">
          <div class="brand-icon">H</div>
          <div class="admin-brand-text">
            <strong>HomeAssist</strong>
            <span>Administration</span>
          </div>
        </div>

        <nav class="admin-nav">
          <button
            type="button"
            class="admin-nav-item active"
          >
            Dashboard
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="provider-applications-button"
          >
            Provider Applications
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="admin-provider-management-button"
          >
            Provider Management
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="admin-reports-button"
          >
            Reports
          </button>
        </nav>

        <button
          type="button"
          class="admin-sign-out"
          id="admin-sign-out-button"
        >
          Sign Out
        </button>
      </aside>

      <section class="admin-content">
        <header class="admin-header">
          <div>
            <p class="portal-label">ADMINISTRATION</p>
            <h1>Dashboard</h1>
            <p
              class="subtitle"
              id="admin-welcome-message"
            ></p>
          </div>
        </header>

        <section class="admin-dashboard-grid">
          <article class="admin-stat-card">
            <div class="admin-stat-card-header">
              <span>Pending Applications</span>
            </div>
            <strong
              class="admin-stat-value"
              id="pending-applications-count"
            >—</strong>
            <p>
              Provider applications awaiting
              administrator review.
            </p>
          </article>

          <article class="admin-stat-card">
            <div class="admin-stat-card-header">
              <span>Verified Providers</span>
            </div>
            <strong
              class="admin-stat-value"
              id="verified-providers-count"
            >—</strong>
            <p>
              Service providers currently
              verified on HomeAssist.
            </p>
          </article>

          <article class="admin-stat-card">
            <div class="admin-stat-card-header">
              <span>Active Bookings</span>
            </div>
            <strong
              class="admin-stat-value"
              id="active-bookings-count"
            >—</strong>
            <p>
              Service bookings currently
              active on the platform.
            </p>
          </article>
        </section>

        <section class="admin-section">
          <div class="admin-section-header">
            <div>
              <h2>Provider Applications</h2>
              <p>
                Review service providers requesting
                access to HomeAssist.
              </p>
            </div>

            <button
              type="button"
              class="text-button"
              id="view-provider-applications-button"
            >
              View Applications
            </button>
          </div>

          <div class="admin-empty-state">
            <strong>Provider verification</strong>
            <p id="pending-applications-summary">
              Loading provider applications...
            </p>
          </div>
        </section>
      </section>
    </main>
  `;

  const welcome = app.querySelector(
    '#admin-welcome-message',
  );

  welcome.textContent =
    `Welcome back${adminName ? `, ${adminName}` : ''}. ` +
    "Here's an overview of the HomeAssist platform.";

  app.querySelector('#admin-sign-out-button')
    .addEventListener('click', onSignOut);

  app.querySelector('#provider-applications-button')
    .addEventListener('click', () => onProviderApplications?.());

  app.querySelector('#view-provider-applications-button')
    .addEventListener('click', () => onProviderApplications?.());

  app.querySelector('#admin-reports-button')
    .addEventListener('click', () => onAdminReports?.());

  app.querySelector('#admin-provider-management-button')
    .addEventListener('click', () => onProviderManagement?.());

  loadAdminDashboardStats(app);
}

async function loadAdminDashboardStats(app) {
  const pendingCount = app.querySelector(
    '#pending-applications-count',
  );
  const pendingSummary = app.querySelector(
    '#pending-applications-summary',
  );
  const verifiedCount = app.querySelector(
    '#verified-providers-count',
  );
  const activeBookingsCount = app.querySelector(
    '#active-bookings-count',
  );

  const results = await Promise.allSettled([
    getPendingProviders(),
    getAdminProviders(),
    getAdminActiveBookingCount(),
  ]);

  if (!app.contains(pendingCount)) {
    return;
  }

  const [pendingResult, providersResult, bookingsResult] = results;

  if (pendingResult.status === 'fulfilled') {
    const count = pendingResult.value.length;
    pendingCount.textContent = String(count);

    if (count === 0) {
      pendingSummary.textContent =
        'There are currently no provider applications awaiting review.';
    } else if (count === 1) {
      pendingSummary.textContent =
        '1 provider application is currently awaiting administrator review.';
    } else {
      pendingSummary.textContent =
        `${count} provider applications are currently awaiting administrator review.`;
    }
  } else {
    console.error('Unable to load pending applications:', pendingResult.reason);
    pendingCount.textContent = '—';
    pendingSummary.textContent =
      'Unable to load provider application information.';
  }

  if (providersResult.status === 'fulfilled') {
    verifiedCount.textContent = String(
      providersResult.value.filter((provider) => provider.isVerified).length,
    );
  } else {
    console.error('Unable to load verified providers:', providersResult.reason);
    verifiedCount.textContent = '—';
  }

  if (bookingsResult.status === 'fulfilled') {
    activeBookingsCount.textContent = String(bookingsResult.value);
  } else {
    console.error('Unable to load active bookings:', bookingsResult.reason);
    activeBookingsCount.textContent = '—';
  }
}

export {
  showAdminDashboardPage,
};
