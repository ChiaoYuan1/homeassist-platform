import {
  approveProviderApplication,
  getPendingProviders,
  getProviderApplication,
  rejectProviderApplication,
} from '../../services/admin-service.js';

import {
  confirmAppAction,
} from '../../utils/app-dialog.js';

async function showProviderApplicationsPage(
  app,
  {
    onDashboard,
    onSignOut,
  },
) {
  app.innerHTML = `
    <main class="admin-layout">

      <aside class="admin-sidebar">

        <div>
          <div class="brand admin-brand">
            <div class="brand-icon">H</div>
            <span class="brand-name">HomeAssist</span>
          </div>

          <p class="admin-sidebar-label">
            ADMINISTRATION
          </p>

          <nav class="admin-nav">
            <button
              type="button"
              class="admin-nav-item"
              id="applications-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="admin-nav-item active"
            >
              Provider Applications
            </button>

            <button
              type="button"
              class="admin-nav-item"
              disabled
            >
              Provider Management
            </button>

            <button
              type="button"
              class="admin-nav-item"
              disabled
            >
              Reports
            </button>
          </nav>
        </div>

        <button
          type="button"
          class="admin-sign-out"
          id="applications-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="admin-content">

        <div class="admin-header">
          <div>
            <p class="portal-label">
              ADMIN REVIEW
            </p>

            <h1>
              Provider Applications
            </h1>

            <p>
              Review submitted provider information,
              locations and verification documents.
            </p>
          </div>
        </div>


        <div class="admin-application-layout">

          <section
            class="admin-application-list-panel"
          >
            <div
              id="pending-provider-list"
              class="admin-application-list"
            >
              <p>Loading applications...</p>
            </div>
          </section>


          <section
            id="provider-review-panel"
            class="admin-provider-review-panel"
          >
            <div class="admin-review-empty">
              <h2>Select an application</h2>
              <p>
                Provider information will appear here
                for administrator review.
              </p>
            </div>
          </section>

        </div>

      </section>

    </main>
  `;


  document
    .querySelector(
      '#applications-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        onDashboard();
      },
    );


  document
    .querySelector(
      '#applications-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  await loadApplications();
}


async function loadApplications() {
  const list = document.querySelector(
    '#pending-provider-list',
  );

  const reviewPanel = document.querySelector(
    '#provider-review-panel',
  );

  try {
    const providers =
      await getPendingProviders();

    if (providers.length === 0) {
      list.innerHTML = `
        <div class="admin-review-empty">
          <h2>No pending applications</h2>
          <p>
            Submitted provider applications will
            appear here.
          </p>
        </div>
      `;

      reviewPanel.innerHTML = `
        <div class="admin-review-empty">
          <h2>Nothing to review</h2>
          <p>
            All submitted provider applications
            have been processed.
          </p>
        </div>
      `;

      return;
    }

    list.innerHTML = providers
      .map(
        (provider) => `
          <article class="admin-application-card">
            <div>
              <span class="admin-status-pill">
                Pending Review
              </span>

              <h3>
                ${escapeHtml(
                  provider.businessName ||
                  provider.displayName ||
                  'Provider Application',
                )}
              </h3>

              <p>
                ${escapeHtml(
                  provider.email ||
                  '',
                )}
              </p>
            </div>

            <button
              type="button"
              class="secondary-button review-provider-button"
              data-provider-id="${escapeAttribute(
                provider.id,
              )}"
            >
              Review
            </button>
          </article>
        `,
      )
      .join('');

    list
      .querySelectorAll(
        '.review-provider-button',
      )
      .forEach(
        (button) => {
          button.addEventListener(
            'click',
            async () => {
              await showProviderReview(
                button.dataset.providerId,
              );
            },
          );
        },
      );
  } catch (error) {
    console.error(
      'Unable to load provider applications:',
      error,
    );

    list.innerHTML = `
      <div class="admin-review-empty">
        <h2>Unable to load applications</h2>
        <p>
          Please refresh the page and try again.
        </p>
      </div>
    `;
  }
}


async function showProviderReview(
  providerId,
) {
  const panel = document.querySelector(
    '#provider-review-panel',
  );

  panel.innerHTML = `
    <div class="admin-review-empty">
      <p>Loading provider application...</p>
    </div>
  `;

  try {
    const provider =
      await getProviderApplication(
        providerId,
      );

    if (!provider) {
      panel.innerHTML = `
        <div class="admin-review-empty">
          <h2>Application not found</h2>
        </div>
      `;

      return;
    }

    renderProviderReview(
      panel,
      provider,
    );
  } catch (error) {
    console.error(
      'Unable to load provider application:',
      error,
    );

    panel.innerHTML = `
      <div class="admin-review-empty">
        <h2>Unable to load application</h2>
      </div>
    `;
  }
}


function renderProviderReview(
  panel,
  provider,
) {
  const categoryIds = Array.isArray(
    provider.categoryIds,
  )
    ? provider.categoryIds
    : [];

  const serviceIds = Array.isArray(
    provider.serviceIds,
  )
    ? provider.serviceIds
    : [];

  const branches = Array.isArray(
    provider.registrationBranches,
  )
    ? provider.registrationBranches
    : [];

  const documents =
    provider.verificationDocuments || {};

  panel.innerHTML = `
    <div class="admin-review-card">

      <div class="admin-review-heading">
        <div>
          <span class="admin-status-pill">
            Pending Review
          </span>

          <h2>
            ${escapeHtml(
              provider.businessName ||
              provider.displayName ||
              'Provider Application',
            )}
          </h2>

          <p>
            ${escapeHtml(
              provider.email ||
              '',
            )}
          </p>
        </div>
      </div>


      ${reviewSection(
        'Business Information',
        `
          <dl class="admin-review-details">
            ${detailRow(
              'Business Name',
              provider.businessName,
            )}

            ${detailRow(
              'Registration Number',
              provider.businessRegistrationNumber,
            )}

            ${detailRow(
              'Business Address',
              provider.businessAddress,
            )}
          </dl>
        `,
      )}


      ${reviewSection(
        'Selected Categories',
        renderTags(
          categoryIds,
        ),
      )}


      ${reviewSection(
        'Selected Services',
        renderTags(
          serviceIds,
        ),
      )}


      ${reviewSection(
        'Service Locations',
        branches.length === 0
          ? '<p>No branch locations submitted.</p>'
          : branches
              .map(
                (branch, index) => `
                  <div class="admin-review-branch">
                    <strong>
                      ${escapeHtml(
                        branch.name ||
                        `Branch ${index + 1}`,
                      )}
                    </strong>

                    <span>
                      ${escapeHtml(
                        branch.address ||
                        '',
                      )}
                    </span>

                    <small>
                      ${escapeHtml(
                        branch.latitude ??
                        '',
                      )},
                      ${escapeHtml(
                        branch.longitude ??
                        '',
                      )}
                    </small>
                  </div>
                `,
              )
              .join(''),
      )}


      ${reviewSection(
        'Verification Documents',
        renderDocuments(
          documents,
          categoryIds,
        ),
      )}


      <section class="admin-review-decision">
        <h3>Administrator Decision</h3>

        <label for="rejection-reason">
          Rejection reason
          <span>(required only when rejecting)</span>
        </label>

        <textarea
          id="rejection-reason"
          rows="4"
          maxlength="500"
          placeholder="Explain what the provider needs to correct before resubmitting."
        ></textarea>

        <p
          id="provider-review-message"
          class="form-message"
        ></p>

        <div class="admin-review-actions">
          <button
            type="button"
            class="danger-button"
            id="reject-provider-button"
          >
            Reject Application
          </button>

          <button
            type="button"
            class="primary-button"
            id="approve-provider-button"
          >
            Approve Provider
          </button>
        </div>
      </section>

    </div>
  `;


  const approveButton =
    document.querySelector(
      '#approve-provider-button',
    );

  const rejectButton =
    document.querySelector(
      '#reject-provider-button',
    );

  const rejectionReason =
    document.querySelector(
      '#rejection-reason',
    );

  const message =
    document.querySelector(
      '#provider-review-message',
    );


  approveButton.addEventListener(
    'click',
    async () => {
      const confirmed = await confirmAppAction({
        title: 'Approve Provider',
        message:
          `Are you sure you want to approve ${provider.businessName || provider.displayName || 'this provider'}? ` +
          'The provider will be granted access to service management features.',
        confirmLabel: 'Approve Provider',
      });

      if (!confirmed) {
        return;
      }

      setDecisionLoading(
        approveButton,
        rejectButton,
        true,
      );

      message.textContent =
        'Approving provider...';

      message.classList.remove(
        'error',
      );

      try {
        await approveProviderApplication(
          provider.id,
        );

        message.textContent =
          'Provider approved successfully.';

        await loadApplications();
      } catch (error) {
        console.error(
          'Unable to approve provider:',
          error,
        );

        message.textContent =
          friendlyFunctionError(
            error,
            'Unable to approve the provider.',
          );

        message.classList.add(
          'error',
        );

        setDecisionLoading(
          approveButton,
          rejectButton,
          false,
        );
      }
    },
  );


  rejectButton.addEventListener(
    'click',
    async () => {
      const reason =
        rejectionReason.value.trim();

      if (!reason) {
        message.textContent =
          'Please enter a rejection reason.';

        message.classList.add(
          'error',
        );

        return;
      }

      const confirmed = await confirmAppAction({
        title: 'Reject Provider Application',
        message:
          `Are you sure you want to reject ${provider.businessName || provider.displayName || 'this provider'}? ` +
          'The provider will be informed that the application was rejected.',
        confirmLabel: 'Reject Application',
        destructive: true,
      });

      if (!confirmed) {
        return;
      }

      setDecisionLoading(
        approveButton,
        rejectButton,
        true,
      );

      message.textContent =
        'Rejecting application...';

      message.classList.remove(
        'error',
      );

      try {
        await rejectProviderApplication(
          provider.id,
          reason,
        );

        message.textContent =
          'Application rejected.';

        await loadApplications();
      } catch (error) {
        console.error(
          'Unable to reject provider:',
          error,
        );

        message.textContent =
          friendlyFunctionError(
            error,
            'Unable to reject the provider.',
          );

        message.classList.add(
          'error',
        );

        setDecisionLoading(
          approveButton,
          rejectButton,
          false,
        );
      }
    },
  );
}


function reviewSection(
  title,
  content,
) {
  return `
    <section class="admin-review-section">
      <h3>${escapeHtml(title)}</h3>
      ${content}
    </section>
  `;
}


function detailRow(
  label,
  value,
) {
  return `
    <div>
      <dt>${escapeHtml(label)}</dt>
      <dd>
        ${escapeHtml(
          value ||
          'Not provided',
        )}
      </dd>
    </div>
  `;
}


function renderTags(values) {
  if (values.length === 0) {
    return '<p>None submitted.</p>';
  }

  return `
    <div class="admin-review-tags">
      ${values
        .map(
          (value) => `
            <span>
              ${escapeHtml(
                formatDisplayName(value),
              )}
            </span>
          `,
        )
        .join('')}
    </div>
  `;
}


function formatDisplayName(value) {
  return String(value ?? '')
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) =>
      letter.toUpperCase(),
    );
}


function renderDocuments(
  documents,
  categoryIds,
) {
  const requirements = [
    ['ssm', 'SSM Business Registration'],
  ];

  if (categoryIds.includes('electrical')) {
    requirements.push(
      [
        'stContractor',
        'ST Electrical Contractor Registration',
      ],
      [
        'stCompetency',
        'ST Competency Certificate',
      ],
    );
  }

  if (
    categoryIds.includes(
      'gas_replacement',
    )
  ) {
    requirements.push(
      [
        'kpdn',
        'KPDN Licence / Supporting Document',
      ],
    );
  }

  return `
    <div class="admin-review-documents">
      ${requirements
        .map(
          ([key, label]) => {
            const document =
              documents[key];

            if (!document?.downloadUrl) {
              return `
                <div class="admin-document-row missing">
                  <div>
                    <strong>${escapeHtml(label)}</strong>
                    <span>Missing</span>
                  </div>
                </div>
              `;
            }

            return `
              <div class="admin-document-row">
                <div>
                  <strong>${escapeHtml(label)}</strong>
                  <span>
                    ${escapeHtml(
                      document.originalName ||
                      'Uploaded document',
                    )}
                  </span>
                </div>

                <a
                  href="${escapeAttribute(
                    safeDocumentUrl(
                      document.downloadUrl,
                    ),
                  )}"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Open Document
                </a>
              </div>
            `;
          },
        )
        .join('')}
    </div>
  `;
}


function safeDocumentUrl(value) {
  const url = String(
    value ?? '',
  ).trim();

  return url.startsWith('https://')
    ? url
    : '#';
}


function setDecisionLoading(
  approveButton,
  rejectButton,
  loading,
) {
  approveButton.disabled = loading;
  rejectButton.disabled = loading;

  approveButton.textContent = loading
    ? 'Processing...'
    : 'Approve Provider';
}


function friendlyFunctionError(
  error,
  fallback,
) {
  const message = String(
    error?.message ?? '',
  );

  if (message.includes(':')) {
    return message
      .split(':')
      .slice(1)
      .join(':')
      .trim() || fallback;
  }

  return message || fallback;
}


function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}


function escapeAttribute(value) {
  return escapeHtml(value);
}


export {
  showProviderApplicationsPage,
};
