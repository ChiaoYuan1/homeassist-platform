import {
  getAdminProviders,
  setAdminProviderListingActive,
} from '../../services/admin-service.js';

function createElement(tag, className, text) {
  const element = document.createElement(tag);

  if (className) {
    element.className = className;
  }

  if (text !== undefined && text !== null) {
    element.textContent = String(text);
  }

  return element;
}

function formatStatus(value) {
  const status = String(value || 'draft');

  return status
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function showAdminProviderManagementPage(
  app,
  {
    onDashboard,
    onProviderApplications,
    onAdminReports,
    onSignOut,
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
            class="admin-nav-item"
            id="management-dashboard-button"
          >
            Dashboard
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="management-applications-button"
          >
            Provider Applications
          </button>

          <button
            type="button"
            class="admin-nav-item active"
          >
            Provider Management
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="management-reports-button"
          >
            Reports
          </button>
        </nav>

        <button
          type="button"
          class="admin-sign-out"
          id="management-sign-out-button"
        >
          Sign Out
        </button>
      </aside>

      <section class="admin-content">
        <header class="admin-header">
          <p class="portal-label">ADMINISTRATION</p>
          <h1>Provider Management</h1>
          <p class="subtitle">
            View registered providers and manage their
            availability on HomeAssist.
          </p>
        </header>

        <section class="admin-section">
          <div class="admin-section-header">
            <div>
              <h2>Registered Providers</h2>
              <p>Providers across the HomeAssist platform.</p>
            </div>

            <button
              type="button"
              class="text-button"
              id="management-refresh-button"
            >
              Refresh
            </button>
          </div>

          <div class="admin-management-filters">
            <label class="admin-management-search">
              Search providers
              <input
                id="management-search"
                type="search"
                placeholder="Business name or email"
              />
            </label>

            <label class="admin-management-filter">
              Application status
              <select id="management-status-filter">
                <option value="all">All providers</option>
                <option value="approved">Approved</option>
                <option value="pending">Pending</option>
                <option value="rejected">Rejected</option>
                <option value="draft">Draft</option>
              </select>
            </label>
          </div>

          <p id="management-message" role="status">
            Loading providers...
          </p>
          <div id="management-provider-list"></div>
        </section>
      </section>
    </main>
  `;

  app.querySelector('#management-dashboard-button')
    .addEventListener('click', onDashboard);

  app.querySelector('#management-applications-button')
    .addEventListener('click', onProviderApplications);

  app.querySelector('#management-reports-button')
    .addEventListener('click', onAdminReports);

  app.querySelector('#management-sign-out-button')
    .addEventListener('click', onSignOut);

  const list = app.querySelector('#management-provider-list');
  const message = app.querySelector('#management-message');
  const search = app.querySelector('#management-search');
  const statusFilter = app.querySelector('#management-status-filter');
  const refreshButton = app.querySelector('#management-refresh-button');

  let providers = [];

  function renderProviders() {
    if (!app.contains(list)) {
      return;
    }

    const searchTerm = search.value.trim().toLowerCase();
    const selectedStatus = statusFilter.value;

    const filtered = providers.filter((provider) => {
      const matchesSearch =
        provider.businessName.toLowerCase().includes(searchTerm) ||
        provider.email.toLowerCase().includes(searchTerm);

      const matchesStatus = selectedStatus === 'all' ||
        provider.approvalStatus === selectedStatus;

      return matchesSearch && matchesStatus;
    });

    list.replaceChildren();
    message.textContent = `${filtered.length} provider(s) shown.`;

    if (filtered.length === 0) {
      list.append(
        createElement(
          'p',
          'admin-management-empty',
          'No providers match the selected filters.',
        ),
      );
      return;
    }

    for (const provider of filtered) {
      const card = createElement('article', 'admin-management-card');
      const information = createElement('div', 'admin-management-info');
      const heading = createElement('h3', '', provider.businessName);
      const email = createElement('p', '', provider.email || 'No email recorded');
      const address = createElement(
        'p',
        '',
        provider.businessAddress || 'No business address recorded',
      );

      const tags = createElement('div', 'admin-management-tags');
      tags.append(
        createElement(
          'span',
          'admin-management-tag',
          `Application: ${formatStatus(provider.approvalStatus)}`,
        ),
      );
      tags.append(
        createElement(
          'span',
          'admin-management-tag',
          provider.hasProviderRecord
            ? (provider.active ? 'Listing: Active' : 'Listing: Inactive')
            : 'Business profile not ready',
        ),
      );
      tags.append(
        createElement(
          'span',
          'admin-management-tag',
          `${provider.serviceIds.length} service(s)`,
        ),
      );

      information.append(heading, email, address, tags);
      card.append(information);

      const actions = createElement('div', 'admin-management-actions');
      const button = createElement(
        'button',
        provider.active ? 'admin-management-disable' : 'primary-button',
        provider.active ? 'Disable Listing' : 'Enable Listing',
      );
      button.type = 'button';

      // Do not activate an unapproved account or a missing provider record.
      const canManageListing = provider.hasProviderRecord &&
        provider.isVerified &&
        provider.approvalStatus === 'approved';

      button.disabled = !canManageListing;
      button.title = canManageListing
        ? 'Changes service listing availability, not login access.'
        : 'Only approved providers with a business profile can be managed.';

      const feedback = createElement('p', 'admin-management-feedback');
      feedback.setAttribute('role', 'status');

      button.addEventListener('click', async () => {
        const newActive = !provider.active;
        const action = newActive ? 'enable' : 'disable';

        const confirmed = await showListingConfirmation(
            provider.businessName,
            action,
        );

        if (!confirmed) {
            return;
        }

        button.disabled = true;
        feedback.textContent = 'Updating listing...';

        try {
          await setAdminProviderListingActive(provider.id, newActive);
          provider.active = newActive;
          renderProviders();
        } catch (error) {
          console.error('Unable to update provider listing:', error);
          feedback.textContent =
            `Unable to update listing: ${error.message}`;
          button.disabled = false;
        }
      });

      actions.append(button, feedback);
      card.append(actions);
      list.append(card);
    }
  }

  async function loadProviders() {
    refreshButton.disabled = true;
    message.textContent = 'Loading providers...';
    list.replaceChildren();

    try {
      const fetched = await getAdminProviders();

      if (!app.contains(list)) {
        return;
      }

      providers = fetched;
      renderProviders();
    } catch (error) {
      console.error('Unable to load providers:', error);

      if (app.contains(message)) {
        message.textContent =
          'Unable to load providers. Check permissions and the browser console.';
      }
    } finally {
      if (app.contains(refreshButton)) {
        refreshButton.disabled = false;
      }
    }
  }

  search.addEventListener('input', renderProviders);
  statusFilter.addEventListener('change', renderProviders);
  refreshButton.addEventListener('click', loadProviders);

  loadProviders();
}


function showListingConfirmation(
  providerName,
  action,
) {
  return new Promise((resolve) => {
    const isDisabling = action === 'disable';

    const dialog = document.createElement('dialog');
    dialog.className = 'admin-confirm-dialog';

    dialog.innerHTML = `
      <div class="admin-confirm-content">
        <div class="admin-confirm-icon">
          !
        </div>

        <h2>
          ${isDisabling ? 'Disable' : 'Enable'} Provider Listing?
        </h2>

        <p class="admin-confirm-message"></p>

        <p class="admin-confirm-note">
          ${
            isDisabling
              ? 'The provider will no longer be available for new customer bookings. Existing bookings will not be automatically cancelled.'
              : 'The provider will become available for new customer bookings again.'
          }
        </p>

        <div class="admin-confirm-actions">
          <button
            type="button"
            class="admin-confirm-cancel"
          >
            Cancel
          </button>

          <button
            type="button"
            class="admin-confirm-submit"
          >
            ${isDisabling ? 'Disable Listing' : 'Enable Listing'}
          </button>
        </div>
      </div>
    `;

    dialog.querySelector(
      '.admin-confirm-message',
    ).textContent =
      `Are you sure you want to ${action} the listing for ${providerName}?`;

    const cancelButton = dialog.querySelector(
      '.admin-confirm-cancel',
    );

    const confirmButton = dialog.querySelector(
      '.admin-confirm-submit',
    );

    const title = dialog.querySelector('h2');
    title.id = 'admin-confirm-title';

    dialog.setAttribute(
      'aria-labelledby',
      title.id,
    );

    function finish(confirmed) {
      dialog.close();
      dialog.remove();
      resolve(confirmed);
    }

    cancelButton.addEventListener(
      'click',
      () => finish(false),
    );

    confirmButton.addEventListener(
      'click',
      () => finish(true),
    );

    dialog.addEventListener(
      'cancel',
      (event) => {
        event.preventDefault();
        finish(false);
      },
    );

    document.body.appendChild(dialog);
    dialog.showModal();

    cancelButton.focus();
  });
}

export {
  showAdminProviderManagementPage,
};
