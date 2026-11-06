import {
  getAdminReports,
  updateAdminReportStatus,
} from '../../services/admin-service.js';

function formatStatus(value) {
  const normalized = String(value ?? 'open');

  if (normalized === 'under_review' || normalized === 'underReview') {
    return 'Under Review';
  }

  if (normalized === 'resolved') {
    return 'Resolved';
  }

  if (normalized === 'dismissed') {
    return 'Dismissed';
  }

  return 'Open';
}

function formatDate(value) {
  if (!value) {
    return 'Not available';
  }

  const date = typeof value.toDate === 'function'
    ? value.toDate()
    : new Date(value);

  if (Number.isNaN(date.getTime())) {
    return 'Not available';
  }

  return new Intl.DateTimeFormat(
    'en-MY',
    {
      dateStyle: 'medium',
      timeStyle: 'short',
      timeZone: 'Asia/Kuala_Lumpur',
    },
  ).format(date);
}

function makeElement(tag, className, text) {
  const element = document.createElement(tag);

  if (className) {
    element.className = className;
  }

  if (text !== undefined && text !== null) {
    element.textContent = String(text);
  }

  return element;
}

function addDetail(container, label, value) {
  const row = makeElement('p', 'admin-report-detail');
  row.append(makeElement('strong', '', `${label}: `));
  row.append(
    document.createTextNode(String(value ?? 'Not available')),
  );
  container.append(row);
}

function showAdminReportsPage(
  app,
  {
    onDashboard,
    onProviderApplications,
    onProviderManagement,
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
            id="admin-reports-dashboard"
          >
            Dashboard
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="admin-reports-applications"
          >
            Provider Applications
          </button>

          <button
            type="button"
            class="admin-nav-item"
            id="admin-reports-provider-management"
          >
            Provider Management
          </button>

          <button
            type="button"
            class="admin-nav-item active"
          >
            Reports
          </button>
        </nav>

        <button
          type="button"
          class="admin-sign-out"
          id="admin-reports-signout"
        >
          Sign Out
        </button>
      </aside>

      <section class="admin-content">
        <header class="admin-header">
          <div>
            <p class="portal-label">ADMINISTRATION</p>
            <h1>Reports &amp; Complaints</h1>
            <p class="subtitle">
              Review customer complaints linked to service bookings.
            </p>
          </div>
        </header>

        <section class="admin-section">
          <div class="admin-section-header">
            <div>
              <h2>Customer Reports</h2>
              <p>
                Only administrators should be able to
                view and update these records.
              </p>
            </div>

            <button
              type="button"
              class="text-button"
              id="refresh-admin-reports"
            >
              Refresh
            </button>
          </div>

          <p id="admin-reports-message" role="status">
            Loading reports...
          </p>
          <div id="admin-reports-list"></div>
        </section>
      </section>
    </main>
  `;

  const dashboardButton = app.querySelector(
    '#admin-reports-dashboard',
  );
  const applicationsButton = app.querySelector(
    '#admin-reports-applications',
  );
  const managementButton = app.querySelector(
    '#admin-reports-provider-management',
  );
  const signoutButton = app.querySelector(
    '#admin-reports-signout',
  );
  const refreshButton = app.querySelector(
    '#refresh-admin-reports',
  );
  const message = app.querySelector(
    '#admin-reports-message',
  );
  const list = app.querySelector(
    '#admin-reports-list',
  );

  dashboardButton.addEventListener('click', onDashboard);
  applicationsButton.addEventListener('click', onProviderApplications);
  managementButton.addEventListener('click', onProviderManagement);
  signoutButton.addEventListener('click', onSignOut);

  async function loadReports() {
    message.textContent = 'Loading reports...';
    list.replaceChildren();
    refreshButton.disabled = true;

    try {
      const reports = await getAdminReports();

      // The page may have changed while the asynchronous request was running.
      if (!app.contains(list)) {
        return;
      }

      if (reports.length === 0) {
        message.textContent = 'No customer complaints have been submitted.';
        return;
      }

      message.textContent = `${reports.length} report(s) found.`;

      for (const report of reports) {
        const card = makeElement('article', 'admin-report-card');
        card.style.cssText =
          'padding:18px;margin:12px 0;border:1px solid #e4e9f1;border-radius:14px;background:#fff;';

        const heading = makeElement(
          'h3',
          '',
          report.subject || 'Untitled report',
        );
        heading.style.margin = '0 0 8px';
        card.append(heading);

        addDetail(card, 'Status', formatStatus(report.status));
        addDetail(card, 'Submitted', formatDate(report.createdAt));
        addDetail(card, 'Customer', report.customerName);
        addDetail(card, 'Provider', report.providerName);
        addDetail(card, 'Branch', report.branchName);
        addDetail(card, 'Assigned technician', report.technicianName);
        addDetail(card, 'Booking reference', report.bookingId || 'Not linked');

        if (report.bookingId) {
          addDetail(card, 'Appointment', formatDate(report.appointmentStart));
          addDetail(card, 'Booking status', report.bookingStatus);
        }

        const description = makeElement(
          'p',
          '',
          report.description || 'No description provided.',
        );
        description.style.cssText = 'white-space:pre-wrap;margin:14px 0;';
        card.append(description);

        const actions = makeElement('div');
        actions.style.cssText =
          'display:flex;gap:10px;flex-wrap:wrap;align-items:center;';

        const feedback = makeElement('span');
        feedback.setAttribute('role', 'status');
        const actionButtons = [];

        for (const [label, status] of [
          ['Under Review', 'under_review'],
          ['Resolve', 'resolved'],
          ['Dismiss', 'dismissed'],
        ]) {
          const button = makeElement('button', 'text-button', label);
          button.type = 'button';
          button.disabled = report.status === status ||
            (report.status === 'underReview' && status === 'under_review');

          button.addEventListener('click', async () => {
            if (
              status === 'dismissed' &&
              !window.confirm('Dismiss this complaint?')
            ) {
              return;
            }

            for (const action of actionButtons) {
              action.disabled = true;
            }

            feedback.textContent = 'Saving...';

            try {
              await updateAdminReportStatus(report.id, status);
              feedback.textContent = 'Updated successfully.';
              await loadReports();
            } catch (error) {
              console.error('Unable to update report:', error);
              feedback.textContent = `Unable to update: ${error.message}`;

              for (const action of actionButtons) {
                action.disabled = false;
              }
            }
          });

          actionButtons.push(button);
          actions.append(button);
        }

        actions.append(feedback);
        card.append(actions);
        list.append(card);
      }
    } catch (error) {
      console.error('Unable to retrieve reports:', error);

      if (app.contains(list)) {
        message.textContent =
          'Unable to load reports. Check admin permissions and the browser console.';
      }
    } finally {
      if (app.contains(refreshButton)) {
        refreshButton.disabled = false;
      }
    }
  }

  refreshButton.addEventListener('click', loadReports);
  loadReports();
}

export {
  showAdminReportsPage,
};
