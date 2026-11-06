import {
  getProviderDashboardData,
} from '../../services/provider-dashboard-service.js';

import {
  addProviderTechnician,
  deleteTechnicianAvailabilityOverride,
  getProviderTechnicians,
  getTechnicianAvailabilityOverrides,
  saveProviderWorkingHours,
  saveTechnicianAvailabilityOverride,
  saveTechnicianAvailabilitySettings,
  updateProviderTechnician,
} from '../../services/provider-service.js';

import {
  showProviderBookingsPage,
} from './provider-bookings-page.js';

import {
  formatStatus,
  getProviderBookings,
} from '../../services/provider-booking-service.js';

import '../../styles/provider-analytics.css';

import {
  setupProviderAnalytics,
} from './provider-analytics-page.js';

async function showProviderDashboardPage(
  app,
  {
    providerId,
    providerName,
    onSignOut,
  },
) {
  app.innerHTML = `
    <main class="provider-dashboard-page">

      <aside class="provider-dashboard-sidebar">

        <div>
          <div class="brand provider-dashboard-brand">
            <div class="brand-icon">H</div>
            <span class="brand-name">
              HomeAssist
            </span>
          </div>

          <p class="portal-label">
            PROVIDER PORTAL
          </p>

          <nav class="provider-dashboard-nav">

            <button
              type="button"
              class="provider-nav-button active"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="provider-bookings-button"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="provider-team-button"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="provider-availability-button"
            >
              Availability
            </button>

          </nav>
        </div>

        <button
          type="button"
          class="text-button"
          id="provider-dashboard-sign-out"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">
          <div>

            <p class="portal-label">
              APPROVED PROVIDER
            </p>

            <h1>
              Welcome, ${escapeHtml(
                providerName ||
                'Service Provider',
              )}
            </h1>

            <p>
              Manage the approved HomeAssist
              provider profile and availability.
            </p>

          </div>
        </div>

        <div
          id="provider-dashboard-content"
          class="provider-dashboard-content"
        >
          <div class="provider-dashboard-loading">
            Loading provider information...
          </div>
        </div>

      </section>

    </main>
  `;


  document
    .querySelector(
      '#provider-dashboard-sign-out',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  document
  .querySelector(
    '#provider-bookings-button',
  )
  .addEventListener(
    'click',
    () => {
      saveProviderRoute(
        providerId,
        'provider-bookings',
      );

      showProviderBookingsPage(
        app,
        {
          providerId,
          providerName,

          onDashboard: () => {
            saveProviderRoute(
              providerId,
              'provider-dashboard',
            );

            showProviderDashboardPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );
          },

          onTeamAvailability: () => {
            saveProviderRoute(
              providerId,
              'provider-team',
            );

            showTeamPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );
          },

          onAvailability: () => {
            saveProviderRoute(
              providerId,
              'provider-availability',
            );

            showAvailabilityPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );
          },

          onSignOut,
        },
      );
    },
  );

  document
    .querySelector(
      '#provider-team-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-team',
        );

        showTeamPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#provider-availability-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-availability',
        );

        showAvailabilityPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  const content =
    document.querySelector(
      '#provider-dashboard-content',
    );


  try {
    const [
      data,
      bookings,
      technicians,
    ] = await Promise.all([
      getProviderDashboardData(
        providerId,
      ),

      getProviderBookings(
        providerId,
      ),

      getProviderTechnicians(
        providerId,
      ),
    ]);


    if (!data) {
      content.innerHTML = `
        <div class="provider-dashboard-empty">

          <h2>
            Provider profile not ready
          </h2>

          <p>
            The approved provider business record
            could not be found yet.
          </p>

        </div>
      `;

      return;
    }


    renderDashboard(
      content,
      data,
    );

  setupDashboardSchedule(
    {
      container: content,

      bookings,

      services:
        data.services ?? [],

      technicians,

      onOpenBooking: (
        bookingId,
      ) => {
        sessionStorage.setItem(
          `homeassist:focusBooking:${providerId}`,
          bookingId,
        );


        document
          .querySelector(
            '#provider-bookings-button',
          )
          ?.click();
      },
    },
  );

  setupProviderAnalytics({
    container: content,
    bookings,
    services: data.services ?? [],
    technicians,
  });

  } catch (error) {
    console.error(
      'Unable to load provider dashboard:',
      error,
    );

    content.innerHTML = `
      <div class="provider-dashboard-empty">

        <h2>
          Unable to load dashboard
        </h2>

        <p>
          Please refresh the page or sign in again.
        </p>

      </div>
    `;
  }
}


async function showTeamPage(
  app,
  {
    providerId,
    providerName,
    onSignOut,
  },
) {
  app.innerHTML = `
    <main class="provider-dashboard-page">

      <aside class="provider-dashboard-sidebar">

        <div>

          <div class="brand provider-dashboard-brand">
            <div class="brand-icon">H</div>

            <span class="brand-name">
              HomeAssist
            </span>
          </div>

          <p class="portal-label">
            PROVIDER PORTAL
          </p>

          <nav class="provider-dashboard-nav">

            <button
              type="button"
              class="provider-nav-button"
              id="team-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="team-bookings-button"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button active"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="team-availability-button"
            >
              Availability
            </button>

          </nav>

        </div>

        <button
          type="button"
          class="text-button"
          id="team-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <p class="portal-label">
            TEAM MANAGEMENT
          </p>

          <div class="provider-team-heading-row">

            <div>

              <h1>
                Technicians
              </h1>

              <p>
                Manage technicians and the services
                they are qualified to handle.
              </p>

            </div>

            <button
              type="button"
              class="primary-button provider-team-add-button"
              id="open-add-technician-button"
            >
              + Add Technician
            </button>

          </div>

        </div>


        <div
          id="team-content"
          class="provider-dashboard-content"
        >
          <div class="provider-dashboard-loading">
            Loading technicians...
          </div>
        </div>

      </section>

    </main>
  `;


  document
    .querySelector(
      '#team-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-dashboard',
        );

        showProviderDashboardPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#team-bookings-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-bookings',
        );

        showProviderBookingsPage(
          app,
          {
            providerId,
            providerName,

            onDashboard: () => {
              saveProviderRoute(
                providerId,
                'provider-dashboard',
              );

              showProviderDashboardPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onTeamAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-team',
              );

              showTeamPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-availability',
              );

              showAvailabilityPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#team-availability-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-availability',
        );

        showAvailabilityPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#open-add-technician-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-team',
        );

        showAddTechnicianPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#team-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  const content =
    document.querySelector(
      '#team-content',
    );


  try {
    const [
      dashboardData,
      technicians,
    ] = await Promise.all([
      getProviderDashboardData(
        providerId,
      ),

      getProviderTechnicians(
        providerId,
      ),
    ]);


    if (!dashboardData) {
      throw new Error(
        'Provider profile was not found.',
      );
    }


    const services =
      dashboardData.services ?? [];

    const branches =
      dashboardData.branches ?? [];


    content.innerHTML = `

      <section class="provider-dashboard-card">

        <p class="portal-label">
          CURRENT TEAM
        </p>

        <h2>
          Technicians
        </h2>

        <p>
          Select a technician to view or manage
          work details.
        </p>

        ${
          technicians.length === 0
            ? `
              <div class="provider-dashboard-empty">

                <h3>
                  No technicians yet
                </h3>

                <p>
                  Add the first technician to start
                  building the provider team.
                </p>

              </div>
            `
            : technicians
                .map(
                  (technician) => `
                    <button
                      type="button"
                      class="provider-technician-card"
                      data-technician-id="${escapeHtml(
                        technician.id,
                      )}"
                    >

                      <strong>
                        ${escapeHtml(
                          technician.name ||
                          'Technician',
                        )}
                      </strong>

                      <span>
                        ${escapeHtml(
                          technician.phone ||
                          'No phone number',
                        )}
                      </span>

                      <small>
                        ${
                          technician
                            .serviceIds
                            ?.length || 0
                        }
                        qualified service(s)
                      </small>

                      <small>
                        ${
                          technician.active === false
                            ? 'Inactive'
                            : 'Active'
                        }
                      </small>

                    </button>
                  `,
                )
                .join('')
        }

      </section>
    `;


    document
      .querySelectorAll(
        '.provider-technician-card',
      )
      .forEach(
        (card) => {
          card.addEventListener(
            'click',
            () => {
              const technicianId =
                card.dataset.technicianId;


              const technician =
                technicians.find(
                  (item) =>
                    item.id ===
                    technicianId,
                );


              if (!technician) {
                return;
              }


              showTechnicianDetailsPage(
                app,
                {
                  providerId,
                  providerName,
                  technician,
                  services,
                  branches,
                  onSignOut,
                },
              );
            },
          );
        },
      );

  } catch (error) {
    console.error(
      'Unable to load technicians:',
      error,
    );


    content.innerHTML = `
      <div class="provider-dashboard-empty">

        <h2>
          Unable to load technicians
        </h2>

        <p>
          Please refresh and try again.
        </p>

      </div>
    `;
  }
}



async function showAddTechnicianPage(
  app,
  {
    providerId,
    providerName,
    onSignOut,
  },
) {
  app.innerHTML = `
    <main class="provider-dashboard-page">

      <aside class="provider-dashboard-sidebar">

        <div>

          <div class="brand provider-dashboard-brand">

            <div class="brand-icon">
              H
            </div>

            <span class="brand-name">
              HomeAssist
            </span>

          </div>

          <p class="portal-label">
            PROVIDER PORTAL
          </p>

          <nav class="provider-dashboard-nav">

            <button
              type="button"
              class="provider-nav-button"
              id="add-technician-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="add-technician-bookings-button"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button active"
              id="add-technician-team-button"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="add-technician-availability-button"
            >
              Availability
            </button>

          </nav>

        </div>


        <button
          type="button"
          class="text-button"
          id="add-technician-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <p class="portal-label">
            TEAM MANAGEMENT
          </p>

          <h1>
            Add Technician
          </h1>

          <p>
            Add a new technician and configure
            the technician's work assignment.
          </p>

        </div>


        <div
          id="add-technician-content"
          class="provider-dashboard-content"
        >
          <div class="provider-dashboard-loading">
            Loading technician form...
          </div>
        </div>

      </section>

    </main>
  `;


  const goBackToTeam = () => {
    saveProviderRoute(
      providerId,
      'provider-team',
    );

    showTeamPage(
      app,
      {
        providerId,
        providerName,
        onSignOut,
      },
    );
  };


  document
    .querySelector(
      '#add-technician-team-button',
    )
    .addEventListener(
      'click',
      goBackToTeam,
    );


  document
    .querySelector(
      '#add-technician-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-dashboard',
        );

        showProviderDashboardPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#add-technician-bookings-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-bookings',
        );

        showProviderBookingsPage(
          app,
          {
            providerId,
            providerName,

            onDashboard: () => {
              saveProviderRoute(
                providerId,
                'provider-dashboard',
              );

              showProviderDashboardPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onTeamAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-team',
              );

              showTeamPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-availability',
              );

              showAvailabilityPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#add-technician-availability-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-availability',
        );

        showAvailabilityPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#add-technician-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  const content =
    document.querySelector(
      '#add-technician-content',
    );


  try {
    const dashboardData =
      await getProviderDashboardData(
        providerId,
      );


    if (!dashboardData) {
      throw new Error(
        'Provider profile was not found.',
      );
    }


    const services =
      dashboardData.services ?? [];

    const branches =
      dashboardData.branches ?? [];


    content.innerHTML = `

      <button
        type="button"
        class="secondary-button add-technician-back-button"
        id="back-to-team-button"
      >
        ← Back to Team
      </button>


      <section class="provider-dashboard-card">

        <p class="portal-label">
          ADD TECHNICIAN
        </p>

        <h2>
          Technician Information
        </h2>

        <p>
          Enter the technician's basic information
          and work assignment.
        </p>


        <div class="form-group">

          <label for="technician-name">
            Technician Name
          </label>

          <input
            type="text"
            id="technician-name"
            placeholder="e.g. Eric"
          />

        </div>


        <div class="form-group">

          <label for="technician-work-email">
            Work Email
          </label>

          <input
            type="email"
            id="technician-work-email"
            placeholder="e.g. eric@company.com"
          />

          <small>
            This email will later be used for
            the technician account invitation.
          </small>

        </div>
        
        <div class="form-group">

          <label for="technician-branch">
            Assigned Branch
          </label>

          <select
            id="technician-branch"
            class="technician-edit-select"
          >

            <option value="">
              Select a branch
            </option>

            ${
              branches.length === 0
                ? `
                  <option
                    value=""
                    disabled
                  >
                    No branches available
                  </option>
                `
                : branches
                    .filter(
                      (branch) =>
                        String(
                          branch.id ?? '',
                        ).trim(),
                    )
                    .map(
                      (branch) => `
                        <option
                          value="${escapeHtml(
                            branch.id,
                          )}"
                        >
                          ${escapeHtml(
                            branch.name ||
                            'Branch',
                          )}
                        </option>
                      `,
                    )
                    .join('')
            }

          </select>

        </div>


        <div class="form-group">

          <label>
            Qualified Services
          </label>

          <p class="technician-edit-help">
            Select the services this technician
            is qualified to handle.
          </p>

          ${
            services.length === 0
              ? `
                <p>
                  No provider services were found.
                </p>
              `
              : services
                  .map(
                    (service) => `
                      <label
                        class="provider-service-checkbox"
                      >

                        <input
                          type="checkbox"
                          name="technician-service"
                          value="${escapeHtml(
                            service.id,
                          )}"
                        />

                        <span>
                          ${escapeHtml(
                            service.name ||
                            formatDisplayName(
                              service.id,
                            ),
                          )}
                        </span>

                      </label>
                    `,
                  )
                  .join('')
          }

        </div>


        <button
          type="button"
          class="primary-button"
          id="add-technician-button"
        >
          Add Technician
        </button>


        <p
          id="technician-message"
          class="form-message"
        ></p>

      </section>
    `;


    document
      .querySelector(
        '#back-to-team-button',
      )
      .addEventListener(
        'click',
        goBackToTeam,
      );


    document
      .querySelector(
        '#add-technician-button',
      )
      .addEventListener(
        'click',
        async () => {
          const message =
            document.querySelector(
              '#technician-message',
            );


          const button =
            document.querySelector(
              '#add-technician-button',
            );

          
          message.textContent =
            '';

          message.classList.remove(
            'error',
          );

          const name =
            document.querySelector(
              '#technician-name',
            ).value;


          const workEmail =
            document.querySelector(
              '#technician-work-email',
            ).value;

          const branchId =
            document.querySelector(
              '#technician-branch',
            ).value;


          const serviceIds =
            Array.from(
              document.querySelectorAll(
                'input[name="technician-service"]:checked',
              ),
            ).map(
              (input) =>
                input.value,
            );

          if (!name.trim()) {
            message.textContent =
              'Please enter the technician name.';

            message.classList.add(
              'error',
            );

            return;
          }


          if (!workEmail.trim()) {
            message.textContent =
              'Please enter the technician work email.';

            message.classList.add(
              'error',
            );

            return;
          }


          const emailPattern =
            /^[^\s@]+@[^\s@]+\.[^\s@]+$/;


          if (
            !emailPattern.test(
              workEmail.trim(),
            )
          ) {
            message.textContent =
              'Please enter a valid work email.';

            message.classList.add(
              'error',
            );

            return;
          }


          if (!branchId) {
            message.textContent =
              'Please assign the technician to a branch.';

            message.classList.add(
              'error',
            );

            return;
          }


          if (
            serviceIds.length === 0
          ) {
            message.textContent =
              'Please select at least one service.';

            message.classList.add(
              'error',
            );

            return;
          }


          button.disabled =
            true;

          button.textContent =
            'Adding...';


          try {
            await addProviderTechnician(
              providerId,
              {
                name,
                workEmail,
                branchId,
                serviceIds,
              },
            );


            saveProviderRoute(
              providerId,
              'provider-team',
            );


            await showTeamPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );

          } catch (error) {
            console.error(
              'Unable to add technician:',
              error,
            );


            button.disabled =
              false;

            button.textContent =
              'Add Technician';


            message.textContent =
              error.message ||
              'Unable to add technician.';

            message.classList.add(
              'error',
            );
          }
        },
      );

  } catch (error) {
    console.error(
      'Unable to load technician form:',
      error,
    );


    content.innerHTML = `
      <div class="provider-dashboard-empty">

        <h2>
          Unable to load technician form
        </h2>

        <p>
          Please return to Team and try again.
        </p>

      </div>
    `;
  }
}

function showTechnicianDetailsPage(
  app,
  {
    providerId,
    providerName,
    technician,
    services,
    branches,
    onSignOut,
    successMessage = '',
  },
) {
  const assignedServiceIds =
    new Set(
      Array.isArray(
        technician.serviceIds,
      )
        ? technician.serviceIds
        : [],
    );


  const providerBranches =
    Array.isArray(
      branches,
    )
      ? branches
      : [];


  app.innerHTML = `
    <main class="provider-dashboard-page">

      <aside class="provider-dashboard-sidebar">

        <div>

          <div class="brand provider-dashboard-brand">

            <div class="brand-icon">
              H
            </div>

            <span class="brand-name">
              HomeAssist
            </span>

          </div>


          <p class="portal-label">
            PROVIDER PORTAL
          </p>


          <nav class="provider-dashboard-nav">

            <button
              type="button"
              class="provider-nav-button"
              id="technician-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="technician-bookings-button"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button active"
              id="technician-team-button"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="technician-availability-button"
            >
              Availability
            </button>

          </nav>

        </div>


        <button
          type="button"
          class="text-button"
          id="technician-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <p class="portal-label">
            TECHNICIAN DETAILS
          </p>

          <h1>
            ${escapeHtml(
              technician.name ||
              'Technician',
            )}
          </h1>

          <p>
            Manage technician work information,
            service qualifications and status.
          </p>

        </div>


        <div class="provider-dashboard-content">

          <button
            type="button"
            class="secondary-button technician-back-button"
            id="technician-back-button"
          >
            ← Back to Team
          </button>


          <section
            class="provider-dashboard-card technician-details-card"
          >

            <div class="technician-details-heading">

              <div>

                <p class="portal-label">
                  PROFILE
                </p>

                <h2>
                  ${escapeHtml(
                    technician.name ||
                    'Technician',
                  )}
                </h2>

              </div>


              <span
                class="
                  technician-status-badge
                  ${
                    technician.active === false
                      ? 'inactive'
                      : 'active'
                  }
                "
              >
                ${
                  technician.active === false
                    ? 'Inactive'
                    : 'Active'
                }
              </span>

            </div>


            <div class="technician-details-grid">

              <div class="technician-detail-item">

                <span>
                  Phone Number
                </span>

                <strong>
                  ${escapeHtml(
                    technician.phone ||
                    'Not provided',
                  )}
                </strong>

              </div>


              <div class="technician-detail-item">

                <span>
                  Technician ID
                </span>

                <strong>
                  ${escapeHtml(
                    technician.id ||
                    'Unavailable',
                  )}
                </strong>

              </div>

            </div>

          </section>


          <section class="provider-dashboard-card">

            <p class="portal-label">
              WORK DETAILS
            </p>

            <h2>
              Technician Assignment
            </h2>

            <p>
              Assign the technician to a branch,
              select qualified services and manage
              whether the technician is active.
            </p>


            <div class="technician-edit-grid">

              <div class="technician-edit-field">

                <label for="technician-branch-select">
                  Assigned Branch
                </label>

                <select
                  id="technician-branch-select"
                  class="technician-edit-select"
                >

                  <option value="">
                    Not assigned
                  </option>

                  ${providerBranches
                    .filter(
                      (branch) =>
                        String(
                          branch.id ?? '',
                        ).trim(),
                    )
                    .map(
                      (branch) => `
                        <option
                          value="${escapeHtml(
                            branch.id,
                          )}"
                          ${
                            technician.branchId ===
                            branch.id
                              ? 'selected'
                              : ''
                          }
                        >
                          ${escapeHtml(
                            branch.name ||
                            'Branch',
                          )}
                        </option>
                      `,
                    )
                    .join('')}

                </select>

              </div>


              <div class="technician-edit-field">

                <label for="technician-status-select">
                  Technician Status
                </label>

                <select
                  id="technician-status-select"
                  class="technician-edit-select"
                >

                  <option
                    value="active"
                    ${
                      technician.active !== false
                        ? 'selected'
                        : ''
                    }
                  >
                    Active
                  </option>

                  <option
                    value="inactive"
                    ${
                      technician.active === false
                        ? 'selected'
                        : ''
                    }
                  >
                    Inactive
                  </option>

                </select>

              </div>

            </div>


            <div class="technician-service-edit-section">

              <label class="technician-edit-label">
                Qualified Services
              </label>

              <p class="technician-edit-help">
                Select the services this technician
                is qualified to handle.
              </p>


              <div class="technician-service-options">

                ${
                  services.length === 0
                    ? `
                      <p>
                        No provider services were found.
                      </p>
                    `
                    : services
                        .map(
                          (service) => `
                            <label
                              class="provider-service-checkbox"
                            >

                              <input
                                type="checkbox"
                                name="technician-detail-service"
                                value="${escapeHtml(
                                  service.id,
                                )}"
                                ${
                                  assignedServiceIds
                                    .has(
                                      service.id,
                                    )
                                    ? 'checked'
                                    : ''
                                }
                              />

                              <span>
                                ${escapeHtml(
                                  service.name ||
                                  formatDisplayName(
                                    service.id,
                                  ),
                                )}
                              </span>

                            </label>
                          `,
                        )
                        .join('')
                }

              </div>

            </div>


            <div class="technician-update-actions">

              <button
                type="button"
                class="primary-button"
                id="save-technician-details-button"
              >
                Save Work Details
              </button>

            </div>


            <p
              id="technician-update-message"
              class="form-message"
            >
              ${escapeHtml(
                successMessage,
              )}
            </p>

          </section>


          <section class="provider-dashboard-card">

            <p class="portal-label">
              AVAILABILITY
            </p>

            <h2>
              Technician Availability
            </h2>

            <p>
              Availability, absence and custom
              working hours are managed from the
              Availability page.
            </p>


            <button
              type="button"
              class="secondary-button"
              id="technician-manage-availability-button"
            >
              Manage Availability
            </button>

          </section>

        </div>

      </section>

    </main>
  `;


  document
    .querySelector(
      '#technician-back-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-team',
        );

        showTeamPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-team-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-team',
        );

        showTeamPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-availability-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-availability',
        );

        showAvailabilityPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-manage-availability-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-availability',
        );

        showAvailabilityPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-dashboard',
        );

        showProviderDashboardPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-bookings-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-bookings',
        );

        showProviderBookingsPage(
          app,
          {
            providerId,
            providerName,

            onDashboard: () => {
              saveProviderRoute(
                providerId,
                'provider-dashboard',
              );

              showProviderDashboardPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onTeamAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-team',
              );

              showTeamPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-availability',
              );

              showAvailabilityPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#save-technician-details-button',
    )
    .addEventListener(
      'click',
      async () => {
        const button =
          document.querySelector(
            '#save-technician-details-button',
          );

        const message =
          document.querySelector(
            '#technician-update-message',
          );

        const branchId =
          document.querySelector(
            '#technician-branch-select',
          ).value;

        const active =
          document.querySelector(
            '#technician-status-select',
          ).value ===
          'active';

        const serviceIds =
          Array.from(
            document.querySelectorAll(
              'input[name="technician-detail-service"]:checked',
            ),
          ).map(
            (input) =>
              input.value,
          );


        message.textContent =
          '';

        message.classList.remove(
          'error',
        );


        if (
          serviceIds.length === 0
        ) {
          message.textContent =
            'Please select at least one qualified service.';

          message.classList.add(
            'error',
          );

          return;
        }


        button.disabled =
          true;

        button.textContent =
          'Saving...';


        try {
          await updateProviderTechnician(
            providerId,
            technician.id,
            {
              branchId,
              serviceIds,
              active,
            },
          );


          const updatedTechnicians =
            await getProviderTechnicians(
              providerId,
            );


          const updatedTechnician =
            updatedTechnicians.find(
              (item) =>
                item.id ===
                technician.id,
            );


          if (!updatedTechnician) {
            throw new Error(
              'Updated technician could not be loaded.',
            );
          }


          showTechnicianDetailsPage(
            app,
            {
              providerId,
              providerName,
              technician:
                updatedTechnician,
              services,
              branches:
                providerBranches,
              onSignOut,

              successMessage:
                'Technician work details saved successfully.',
            },
          );

        } catch (error) {
          console.error(
            'Unable to update technician:',
            error,
          );


          button.disabled =
            false;

          button.textContent =
            'Save Work Details';


          message.textContent =
            error.message ||
            'Unable to save technician work details.';

          message.classList.add(
            'error',
          );
        }
      },
    );


  document
    .querySelector(
      '#technician-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );
}

async function showAvailabilityPage(
  app,
  {
    providerId,
    providerName,
    onSignOut,
  },
) {
  app.innerHTML = `
    <main class="provider-dashboard-page">

      <aside class="provider-dashboard-sidebar">

        <div>

          <div class="brand provider-dashboard-brand">
            <div class="brand-icon">H</div>

            <span class="brand-name">
              HomeAssist
            </span>
          </div>

          <p class="portal-label">
            PROVIDER PORTAL
          </p>

          <nav class="provider-dashboard-nav">

            <button
              type="button"
              class="provider-nav-button"
              id="availability-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="availability-bookings-button"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="availability-team-button"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button active"
            >
              Availability
            </button>

          </nav>

        </div>

        <button
          type="button"
          class="text-button"
          id="availability-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <p class="portal-label">
            AVAILABILITY
          </p>

          <h1>
            Business Availability
          </h1>

          <p>
            Manage operating hours and
            technician availability.
          </p>

        </div>

        <div
          id="availability-content"
          class="provider-dashboard-content"
        >
          <div class="provider-dashboard-loading">
            Loading availability...
          </div>
        </div>

      </section>

    </main>
  `;


  document
    .querySelector(
      '#availability-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-dashboard',
        );

        showProviderDashboardPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
  .querySelector(
    '#availability-bookings-button',
  )
  .addEventListener(
    'click',
    () => {
      saveProviderRoute(
        providerId,
        'provider-bookings',
      );

      showProviderBookingsPage(
        app,
        {
          providerId,
          providerName,

          onDashboard: () => {
            saveProviderRoute(
              providerId,
              'provider-dashboard',
            );

            showProviderDashboardPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );
          },

          onTeamAvailability: () => {
            saveProviderRoute(
              providerId,
              'provider-team',
            );

            showTeamPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );
          },

          onAvailability: () => {
            saveProviderRoute(
              providerId,
              'provider-availability',
            );

            showAvailabilityPage(
              app,
              {
                providerId,
                providerName,
                onSignOut,
              },
            );
          },

          onSignOut,
        },
      );
    },
  );

  document
    .querySelector(
      '#availability-team-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-team',
        );

        showTeamPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );

  document
    .querySelector(
      '#availability-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  const content =
    document.querySelector(
      '#availability-content',
    );


  try {
    const [
      dashboardData,
      technicians,
    ] = await Promise.all([
      getProviderDashboardData(
        providerId,
      ),

      getProviderTechnicians(
        providerId,
      ),
    ]);


    if (!dashboardData) {
      throw new Error(
        'Provider profile was not found.',
      );
    }


    const provider =
      dashboardData.provider;


    const days = [
      ['monday', 'Monday'],
      ['tuesday', 'Tuesday'],
      ['wednesday', 'Wednesday'],
      ['thursday', 'Thursday'],
      ['friday', 'Friday'],
      ['saturday', 'Saturday'],
      ['sunday', 'Sunday'],
    ];


    content.innerHTML = `

      <section class="provider-dashboard-card">

        <p class="portal-label">
          OPERATING HOURS
        </p>

        <h2>
          Weekly Availability
        </h2>

        <p>
          These hours determine when customers
          can request appointments.
        </p>

        <div id="working-hours-list">

          ${days
            .map(
              ([dayKey, dayLabel]) => {
                const hours =
                  provider
                    .workingHours?.[
                      dayKey
                    ];

                const enabled =
                  hours?.enabled === true;

                return `
                  <div
                    class="provider-dashboard-list-item working-hours-row"
                    data-day="${dayKey}"
                  >

                    <strong>
                      ${dayLabel}
                    </strong>

                    <label>
                      <input
                        type="checkbox"
                        class="hours-enabled"
                        ${
                          enabled
                            ? 'checked'
                            : ''
                        }
                      />

                      Open
                    </label>

                    <div class="form-group">

                      <label>
                        Opening Time
                      </label>

                      <input
                        type="time"
                        class="hours-start"
                        value="${minutesToTime(
                          hours
                            ?.startMinute ??
                          540,
                        )}"
                      />

                    </div>

                    <div class="form-group">

                      <label>
                        Closing Time
                      </label>

                      <input
                        type="time"
                        class="hours-end"
                        value="${minutesToTime(
                          hours
                            ?.endMinute ??
                          1080,
                        )}"
                      />

                    </div>

                  </div>
                `;
              },
            )
            .join('')}

        </div>

        <button
          type="button"
          class="primary-button"
          id="save-working-hours-button"
        >
          Save Operating Hours
        </button>

        <p
          id="working-hours-message"
          class="form-message"
        ></p>

      </section>


      <section class="provider-dashboard-card">

        <p class="portal-label">
          TECHNICIAN AVAILABILITY
        </p>

        <h2>
          Team Availability
        </h2>

        <p>
          Manage each technician's regular schedule,
          leave, absence and temporary working-hour
          changes.
        </p>

        ${
          technicians.length === 0
            ? `
              <div class="provider-dashboard-empty">

                <h3>
                  No technicians yet
                </h3>

                <p>
                  Add technicians before managing
                  individual availability.
                </p>

              </div>
            `
            : technicians
                .map(
                  (technician) => `
                    <button
                      type="button"
                      class="provider-technician-card availability-technician-card"
                      data-technician-id="${escapeHtml(
                        technician.id,
                      )}"
                    >

                      <strong>
                        ${escapeHtml(
                          technician.name ||
                          'Technician',
                        )}
                      </strong>

                      <span>
                        ${
                          technician.availabilityMode ===
                          'custom_weekly'
                            ? 'Custom weekly schedule'
                            : 'Follows business operating hours'
                        }
                      </span>

                      <small>
                        ${
                          technician.active === false
                            ? 'Inactive'
                            : 'Active'
                        }
                      </small>

                    </button>
                  `,
                )
                .join('')
        }

      </section>
    `;

    document
  .querySelectorAll(
    '.availability-technician-card',
  )
  .forEach(
    (card) => {
      card.addEventListener(
        'click',
        () => {
          const technician =
            technicians.find(
              (item) =>
                item.id ===
                card.dataset.technicianId,
            );


          if (!technician) {
            return;
          }


          showTechnicianAvailabilityPage(
            app,
            {
              providerId,
              providerName,
              technician,

              providerWorkingHours:
                provider.workingHours ??
                {},

              onSignOut,
            },
          );
        },
      );
    },
  );

    document
      .querySelector(
        '#save-working-hours-button',
      )
      .addEventListener(
        'click',
        async () => {
          const message =
            document.querySelector(
              '#working-hours-message',
            );

          const button =
            document.querySelector(
              '#save-working-hours-button',
            );

          const workingHours = {};

          let invalidHours = false;


          document
            .querySelectorAll(
              '.working-hours-row',
            )
            .forEach(
              (row) => {
                const day =
                  row.dataset.day;

                const enabled =
                  row.querySelector(
                    '.hours-enabled',
                  ).checked;

                const start =
                  timeToMinutes(
                    row.querySelector(
                      '.hours-start',
                    ).value,
                  );

                const end =
                  timeToMinutes(
                    row.querySelector(
                      '.hours-end',
                    ).value,
                  );


                if (
                  enabled &&
                  end <= start
                ) {
                  invalidHours = true;
                }


                workingHours[day] = {
                  enabled,

                  startMinute:
                    start,

                  endMinute:
                    end,
                };
              },
            );


          if (invalidHours) {
            message.textContent =
              'Closing time must be later than opening time.';

            return;
          }


          button.disabled = true;

          button.textContent =
            'Saving...';

          message.textContent = '';


          try {
            await saveProviderWorkingHours(
              providerId,
              workingHours,
            );

            message.textContent =
              'Operating hours saved successfully.';
          } catch (error) {
            console.error(
              'Unable to save operating hours:',
              error,
            );

            message.textContent =
              'Unable to save operating hours.';
          } finally {
            button.disabled = false;

            button.textContent =
              'Save Operating Hours';
          }
        },
      );
  } catch (error) {
    console.error(
      'Unable to load availability:',
      error,
    );

    content.innerHTML = `
      <div class="provider-dashboard-empty">

        <h2>
          Unable to load availability
        </h2>

        <p>
          Please refresh and try again.
        </p>

      </div>
    `;
  }
}

async function showTechnicianAvailabilityPage(
  app,
  {
    providerId,
    providerName,
    technician,
    providerWorkingHours,
    onSignOut,
    successMessage = '',
  },
) {
  app.innerHTML = `
    <main class="provider-dashboard-page">

      <aside class="provider-dashboard-sidebar">

        <div>

          <div class="brand provider-dashboard-brand">
            <div class="brand-icon">H</div>

            <span class="brand-name">
              HomeAssist
            </span>
          </div>

          <p class="portal-label">
            PROVIDER PORTAL
          </p>

          <nav class="provider-dashboard-nav">

            <button
              type="button"
              class="provider-nav-button"
              id="technician-availability-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="technician-availability-bookings-button"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="technician-availability-team-button"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button active"
              id="technician-availability-main-button"
            >
              Availability
            </button>

          </nav>

        </div>


        <button
          type="button"
          class="text-button"
          id="technician-availability-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <p class="portal-label">
            TECHNICIAN AVAILABILITY
          </p>

          <h1>
            ${escapeHtml(
              technician.name ||
              'Technician',
            )}
          </h1>

          <p>
            Manage the regular work schedule
            and specific-date changes.
          </p>

        </div>


        <div
          id="technician-availability-content"
          class="provider-dashboard-content"
        >
          <div class="provider-dashboard-loading">
            Loading technician availability...
          </div>
        </div>

      </section>

    </main>
  `;


  const goToAvailability = () => {
    saveProviderRoute(
      providerId,
      'provider-availability',
    );

    showAvailabilityPage(
      app,
      {
        providerId,
        providerName,
        onSignOut,
      },
    );
  };


  document
    .querySelector(
      '#technician-availability-main-button',
    )
    .addEventListener(
      'click',
      goToAvailability,
    );


  document
    .querySelector(
      '#technician-availability-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-dashboard',
        );

        showProviderDashboardPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-availability-team-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-team',
        );

        showTeamPage(
          app,
          {
            providerId,
            providerName,
            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-availability-bookings-button',
    )
    .addEventListener(
      'click',
      () => {
        saveProviderRoute(
          providerId,
          'provider-bookings',
        );

        showProviderBookingsPage(
          app,
          {
            providerId,
            providerName,

            onDashboard: () => {
              saveProviderRoute(
                providerId,
                'provider-dashboard',
              );

              showProviderDashboardPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onTeamAvailability: () => {
              saveProviderRoute(
                providerId,
                'provider-team',
              );

              showTeamPage(
                app,
                {
                  providerId,
                  providerName,
                  onSignOut,
                },
              );
            },

            onAvailability:
              goToAvailability,

            onSignOut,
          },
        );
      },
    );


  document
    .querySelector(
      '#technician-availability-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  const content =
    document.querySelector(
      '#technician-availability-content',
    );


  try {
    const overrides =
      await getTechnicianAvailabilityOverrides(
        providerId,
        technician.id,
      );


    const availabilityMode =
      technician.availabilityMode ===
      'custom_weekly'
        ? 'custom_weekly'
        : 'business_hours';


    const weeklyAvailability =
      technician.weeklyAvailability ??
      {};


    const days = [
      ['monday', 'Monday'],
      ['tuesday', 'Tuesday'],
      ['wednesday', 'Wednesday'],
      ['thursday', 'Thursday'],
      ['friday', 'Friday'],
      ['saturday', 'Saturday'],
      ['sunday', 'Sunday'],
    ];


    const statusLabels = {
      available:
        'Available',

      absent:
        'Absent',

      on_leave:
        'On Leave',

      custom_hours:
        'Custom Hours',
    };


    content.innerHTML = `

      <button
        type="button"
        class="secondary-button technician-back-button"
        id="back-to-availability-button"
      >
        ← Back to Availability
      </button>


      <section class="provider-dashboard-card">

        <p class="portal-label">
          REGULAR SCHEDULE
        </p>

        <h2>
          Default Availability
        </h2>

        <p>
          Choose whether this technician normally
          follows the provider's business operating
          hours or uses a different weekly schedule.
        </p>


        <div class="availability-mode-options">

          <label class="availability-mode-option">

            <input
              type="radio"
              name="technician-availability-mode"
              value="business_hours"
              ${
                availabilityMode ===
                'business_hours'
                  ? 'checked'
                  : ''
              }
            />

            <div>
              <strong>
                Follow Business Operating Hours
              </strong>

              <span>
                Use the provider's normal opening
                and closing hours.
              </span>
            </div>

          </label>


          <label class="availability-mode-option">

            <input
              type="radio"
              name="technician-availability-mode"
              value="custom_weekly"
              ${
                availabilityMode ===
                'custom_weekly'
                  ? 'checked'
                  : ''
              }
            />

            <div>
              <strong>
                Custom Weekly Schedule
              </strong>

              <span>
                Use a recurring schedule specifically
                for this technician.
              </span>
            </div>

          </label>

        </div>


        <div
          id="technician-weekly-schedule"
          ${
            availabilityMode ===
            'custom_weekly'
              ? ''
              : 'hidden'
          }
        >

          <div class="technician-weekly-heading">

            <h3>
              Weekly Schedule
            </h3>

            <p>
              Disable a day to make it a regular
              weekly off-day.
            </p>

          </div>


          ${days
            .map(
              ([dayKey, dayLabel]) => {
                const technicianHours =
                  weeklyAvailability[
                    dayKey
                  ];


                const businessHours =
                  providerWorkingHours?.[
                    dayKey
                  ];


                const hours =
                  technicianHours ??
                  businessHours ??
                  {};


                const enabled =
                  hours.enabled ===
                  true;


                return `
                  <div
                    class="provider-dashboard-list-item working-hours-row technician-weekly-row"
                    data-day="${dayKey}"
                  >

                    <strong>
                      ${dayLabel}
                    </strong>


                    <label>
                      <input
                        type="checkbox"
                        class="technician-day-enabled"
                        ${
                          enabled
                            ? 'checked'
                            : ''
                        }
                      />

                      Working
                    </label>


                    <div class="form-group">

                      <label>
                        Start Time
                      </label>

                      <input
                        type="time"
                        class="technician-day-start"
                        value="${minutesToTime(
                          hours
                            .startMinute ??
                          540,
                        )}"
                      />

                    </div>


                    <div class="form-group">

                      <label>
                        End Time
                      </label>

                      <input
                        type="time"
                        class="technician-day-end"
                        value="${minutesToTime(
                          hours
                            .endMinute ??
                          1080,
                        )}"
                      />

                    </div>

                  </div>
                `;
              },
            )
            .join('')}

        </div>


        <button
          type="button"
          class="primary-button"
          id="save-technician-availability-button"
        >
          Save Regular Schedule
        </button>


        <p
          id="technician-availability-message"
          class="form-message"
        >
          ${escapeHtml(
            successMessage,
          )}
        </p>

      </section>


      <section class="provider-dashboard-card">

        <p class="portal-label">
          SCHEDULE EXCEPTIONS
        </p>

        <h2>
          Specific-Date Changes
        </h2>

        <p>
          Add a temporary change without affecting
          the technician's normal weekly schedule.
        </p>


        <div class="technician-exception-form">

          <div class="form-group">

            <label for="technician-exception-date">
              Date
            </label>

            <input
              type="date"
              id="technician-exception-date"
            />

          </div>


          <div class="form-group">

            <label for="technician-exception-status">
              Status
            </label>

            <select
              id="technician-exception-status"
              class="technician-edit-select"
            >

              <option value="available">
                Available
              </option>

              <option value="absent">
                Absent
              </option>

              <option value="on_leave">
                On Leave
              </option>

              <option value="custom_hours">
                Custom Hours
              </option>

            </select>

          </div>


          <div
            id="technician-exception-custom-hours"
            class="technician-exception-custom-hours"
            hidden
          >

            <div class="form-group">

              <label for="technician-exception-start">
                Start Time
              </label>

              <input
                type="time"
                id="technician-exception-start"
                value="09:00"
              />

            </div>


            <div class="form-group">

              <label for="technician-exception-end">
                End Time
              </label>

              <input
                type="time"
                id="technician-exception-end"
                value="18:00"
              />

            </div>

          </div>


          <button
            type="button"
            class="primary-button technician-add-exception-button"
            id="save-technician-exception-button"
          >
            + Add Schedule Exception
          </button>


          <p
            id="technician-exception-message"
            class="form-message"
          ></p>

        </div>


        <div class="technician-exception-list">

          ${
            overrides.length === 0
              ? `
                <div class="provider-dashboard-empty">

                  <h3>
                    No schedule exceptions
                  </h3>

                  <p>
                    This technician currently follows
                    the regular schedule without any
                    date-specific changes.
                  </p>

                </div>
              `
              : overrides
                  .map(
                    (override) => `
                      <div
                        class="provider-dashboard-list-item technician-exception-item"
                      >

                        <div>

                          <strong>
                            ${escapeHtml(
                              override.date ||
                              override.id,
                            )}
                          </strong>

                          <span>
                            ${escapeHtml(
                              statusLabels[
                                override.status
                              ] ||
                              override.status ||
                              'Unknown',
                            )}
                          </span>

                          ${
                            override.status ===
                            'custom_hours'
                              ? `
                                <small>
                                  ${escapeHtml(
                                    minutesToTime(
                                      override
                                        .startMinute ??
                                      0,
                                    ),
                                  )}
                                  –
                                  ${escapeHtml(
                                    minutesToTime(
                                      override
                                        .endMinute ??
                                      0,
                                    ),
                                  )}
                                </small>
                              `
                              : ''
                          }

                        </div>


                        <button
                          type="button"
                          class="secondary-button delete-technician-exception-button"
                          data-exception-date="${escapeHtml(
                            override.date ||
                            override.id,
                          )}"
                        >
                          Remove
                        </button>

                      </div>
                    `,
                  )
                  .join('')
          }

        </div>

      </section>
    `;


    document
      .querySelector(
        '#back-to-availability-button',
      )
      .addEventListener(
        'click',
        goToAvailability,
      );


    const weeklySchedule =
      document.querySelector(
        '#technician-weekly-schedule',
      );


    document
      .querySelectorAll(
        'input[name="technician-availability-mode"]',
      )
      .forEach(
        (radio) => {
          radio.addEventListener(
            'change',
            () => {
              weeklySchedule.hidden =
                radio.value !==
                  'custom_weekly' ||
                !radio.checked;
            },
          );
        },
      );


    document
      .querySelector(
        '#save-technician-availability-button',
      )
      .addEventListener(
        'click',
        async () => {
          const button =
            document.querySelector(
              '#save-technician-availability-button',
            );


          const message =
            document.querySelector(
              '#technician-availability-message',
            );


          const selectedMode =
            document.querySelector(
              'input[name="technician-availability-mode"]:checked',
            ).value;


          const updatedWeeklyAvailability =
            {};


          let invalidHours =
            false;


          document
            .querySelectorAll(
              '.technician-weekly-row',
            )
            .forEach(
              (row) => {
                const day =
                  row.dataset.day;


                const enabled =
                  row.querySelector(
                    '.technician-day-enabled',
                  ).checked;


                const startMinute =
                  timeToMinutes(
                    row.querySelector(
                      '.technician-day-start',
                    ).value,
                  );


                const endMinute =
                  timeToMinutes(
                    row.querySelector(
                      '.technician-day-end',
                    ).value,
                  );


                if (
                  enabled &&
                  endMinute <=
                    startMinute
                ) {
                  invalidHours =
                    true;
                }


                updatedWeeklyAvailability[
                  day
                ] = {
                  enabled,
                  startMinute,
                  endMinute,
                };
              },
            );


          message.textContent =
            '';

          message.classList.remove(
            'error',
          );


          if (
            selectedMode ===
              'custom_weekly' &&
            invalidHours
          ) {
            message.textContent =
              'End time must be later than start time for each working day.';

            message.classList.add(
              'error',
            );

            return;
          }


          button.disabled =
            true;

          button.textContent =
            'Saving...';


          try {
            await saveTechnicianAvailabilitySettings(
              providerId,
              technician.id,
              {
                availabilityMode:
                  selectedMode,

                weeklyAvailability:
                  updatedWeeklyAvailability,
              },
            );


            const updatedTechnicians =
              await getProviderTechnicians(
                providerId,
              );


            const updatedTechnician =
              updatedTechnicians.find(
                (item) =>
                  item.id ===
                  technician.id,
              );


            if (!updatedTechnician) {
              throw new Error(
                'Updated technician could not be loaded.',
              );
            }


            showTechnicianAvailabilityPage(
              app,
              {
                providerId,
                providerName,

                technician:
                  updatedTechnician,

                providerWorkingHours,

                onSignOut,

                successMessage:
                  'Regular technician schedule saved successfully.',
              },
            );

          } catch (error) {
            console.error(
              'Unable to save technician availability:',
              error,
            );


            button.disabled =
              false;

            button.textContent =
              'Save Regular Schedule';


            message.textContent =
              error.message ||
              'Unable to save technician availability.';

            message.classList.add(
              'error',
            );
          }
        },
      );


    const exceptionStatus =
      document.querySelector(
        '#technician-exception-status',
      );


    const customHours =
      document.querySelector(
        '#technician-exception-custom-hours',
      );


    exceptionStatus
      .addEventListener(
        'change',
        () => {
          customHours.hidden =
            exceptionStatus.value !==
            'custom_hours';
        },
      );


    document
      .querySelector(
        '#save-technician-exception-button',
      )
      .addEventListener(
        'click',
        async () => {
          const button =
            document.querySelector(
              '#save-technician-exception-button',
            );


          const message =
            document.querySelector(
              '#technician-exception-message',
            );


          const date =
            document.querySelector(
              '#technician-exception-date',
            ).value;


          const status =
            exceptionStatus.value;


          message.textContent =
            '';

          message.classList.remove(
            'error',
          );


          if (!date) {
            message.textContent =
              'Please select a date.';

            message.classList.add(
              'error',
            );

            return;
          }


          let startMinute;
          let endMinute;


          if (
            status ===
            'custom_hours'
          ) {
            startMinute =
              timeToMinutes(
                document.querySelector(
                  '#technician-exception-start',
                ).value,
              );


            endMinute =
              timeToMinutes(
                document.querySelector(
                  '#technician-exception-end',
                ).value,
              );


            if (
              endMinute <=
              startMinute
            ) {
              message.textContent =
                'Custom end time must be later than start time.';

              message.classList.add(
                'error',
              );

              return;
            }
          }


          button.disabled =
            true;

          button.textContent =
            'Saving...';


          try {
            await saveTechnicianAvailabilityOverride(
              providerId,
              technician.id,
              {
                date,
                status,
                startMinute,
                endMinute,
              },
            );


            showTechnicianAvailabilityPage(
              app,
              {
                providerId,
                providerName,
                technician,
                providerWorkingHours,
                onSignOut,

                successMessage:
                  'Schedule exception saved successfully.',
              },
            );

          } catch (error) {
            console.error(
              'Unable to save schedule exception:',
              error,
            );


            button.disabled =
              false;

            button.textContent =
              '+ Add Schedule Exception';


            message.textContent =
              error.message ||
              'Unable to save schedule exception.';

            message.classList.add(
              'error',
            );
          }
        },
      );


    document
      .querySelectorAll(
        '.delete-technician-exception-button',
      )
      .forEach(
        (button) => {
          button.addEventListener(
            'click',
            async () => {
              const date =
                button.dataset
                  .exceptionDate;


              button.disabled =
                true;

              button.textContent =
                'Removing...';


              try {
                await deleteTechnicianAvailabilityOverride(
                  providerId,
                  technician.id,
                  date,
                );


                const updatedTechnicians =
                  await getProviderTechnicians(
                    providerId,
                  );


                const updatedTechnician =
                  updatedTechnicians.find(
                    (item) =>
                      item.id ===
                      technician.id,
                  );


                if (!updatedTechnician) {
                  throw new Error(
                    'Updated technician could not be loaded.',
                  );
                }


                showTechnicianAvailabilityPage(
                  app,
                  {
                    providerId,
                    providerName,

                    technician:
                      updatedTechnician,

                    providerWorkingHours,
                    onSignOut,

                    successMessage:
                      'Schedule exception removed.',
                  },
                );

              } catch (error) {
                console.error(
                  'Unable to remove schedule exception:',
                  error,
                );


                button.disabled =
                  false;

                button.textContent =
                  'Remove';
              }
            },
          );
        },
      );

  } catch (error) {
    console.error(
      'Unable to load technician availability:',
      error,
    );


    content.innerHTML = `
      <div class="provider-dashboard-empty">

        <h2>
          Unable to load technician availability
        </h2>

        <p>
          Please return to Availability and try again.
        </p>

      </div>
    `;
  }
}

function renderDashboard(
  container,
  {
    provider,
    branches,
    services,
    bookingCount,
    activeBookingCount,
  },
) {
  container.innerHTML = `
    <section class="provider-dashboard-summary">

      <article class="provider-summary-card">

        <span>
          Verification
        </span>

        <strong>
          ${escapeHtml(
            provider.verificationStatus ||
            'unknown',
          )}
        </strong>

      </article>


      <article class="provider-summary-card">

        <span>
          Branches
        </span>

        <strong>
          ${branches.length}
        </strong>

      </article>


      <article class="provider-summary-card">

        <span>
          Services
        </span>

        <strong>
          ${services.length}
        </strong>

      </article>


      <article class="provider-summary-card">

        <span>
          Active Bookings
        </span>

        <strong>
          ${activeBookingCount}
        </strong>

      </article>

    </section>


    <section class="provider-dashboard-card">

      <p class="portal-label">
        BUSINESS PROFILE
      </p>

      <h2>
        ${escapeHtml(
          provider.businessName ||
          'Provider Business',
        )}
      </h2>

      <p>
        ${escapeHtml(
          provider.businessAddress ||
          'No business address saved.',
        )}
      </p>

      <div class="provider-dashboard-meta">

        <span>
          ${
            provider.active === false
              ? 'Inactive'
              : 'Active'
          }
        </span>

        <span>
          ${bookingCount}
          total booking${
            bookingCount === 1
              ? ''
              : 's'
          }
        </span>

      </div>

    </section>


    <section class="provider-dashboard-grid">

      <article class="provider-dashboard-card">

        <p class="portal-label">
          SERVICE LOCATIONS
        </p>

        <h2>
          Branches
        </h2>

        ${
          branches.length === 0
            ? `
              <p>
                No branch locations found.
              </p>
            `
            : branches
                .map(
                  (branch) => `
                    <div
                      class="provider-dashboard-list-item"
                    >

                      <strong>
                        ${escapeHtml(
                          branch.name ||
                          'Branch',
                        )}
                      </strong>

                      <span>
                        ${escapeHtml(
                          branch.address ||
                          '',
                        )}
                      </span>

                      <small>
                        ${Number(
                          branch.latitude,
                        ).toFixed(5)},
                        ${Number(
                          branch.longitude,
                        ).toFixed(5)}
                      </small>

                    </div>
                  `,
                )
                .join('')
        }

      </article>


      <article class="provider-dashboard-card">

        <p class="portal-label">
          SERVICES
        </p>

        <h2>
          Services Offered
        </h2>

        ${
          services.length === 0
            ? `
              <p>
                No active services found.
              </p>
            `
            : services
                .map(
                  (service) => `
                    <div
                      class="provider-dashboard-list-item"
                    >

                      <strong>
                        ${escapeHtml(
                          service.name ||
                          service.id,
                        )}
                      </strong>

                      <span>
                        ${escapeHtml(
                          formatDisplayName(
                            service.categoryId ||
                            '',
                          ),
                        )}
                      </span>

                    </div>
                  `,
                )
                .join('')
        }

      </article>

    </section>

    <section class="provider-dashboard-card">

      <p class="portal-label">
        SCHEDULE
      </p>

      <h2>
        Booking Calendar
      </h2>

      <p>
        View scheduled customer appointments
        by date and technician.
      </p>


      <div
        id="provider-dashboard-schedule"
        class="provider-dashboard-schedule"
      >
        <div class="provider-dashboard-loading">
          Loading schedule...
        </div>
      </div>

    </section>
  `;
}

function setupDashboardSchedule(
  {
    container,
    bookings,
    services,
    technicians,
    onOpenBooking,
  },
) {
  const scheduleContainer =
    container.querySelector(
      '#provider-dashboard-schedule',
    );


  if (!scheduleContainer) {
    return;
  }


  const serviceNames =
    new Map(
      (services ?? []).map(
        (service) => [
          service.id,
          service.name ||
          formatDisplayName(
            service.id,
          ),
        ],
      ),
    );


  const technicianNames =
    new Map(
      (technicians ?? []).map(
        (technician) => [
          technician.id,
          technician.name ||
          'Technician',
        ],
      ),
    );


  const now =
  new Date();

  const scheduleBookings =
    (bookings ?? [])
      .map(
        (booking) => {
          const start =
            bookingTimestampToDate(
              booking.appointmentStart,
            );

          const end =
            bookingTimestampToDate(
              booking.appointmentEnd,
            );


          return {
            ...booking,
            _scheduleStart: start,
            _scheduleEnd: end,
          };
        },
      )
      .filter(
        (booking) => {
          if (
            !booking._scheduleStart
          ) {
            return false;
          }


          if (
            booking.status ===
              'rejected' ||
            booking.status ===
              'cancelled'
          ) {
            return false;
          }


          const bookingEnd =
            booking._scheduleEnd ??
            booking._scheduleStart;


          if (
            bookingEnd < now
          ) {
            return false;
          }


          return true;
        },
      );


  const bookingsByDate =
    new Map();


  scheduleBookings.forEach(
    (booking) => {
      const key =
        dashboardDateKey(
          booking._scheduleStart,
        );


      if (
        !bookingsByDate.has(
          key,
        )
      ) {
        bookingsByDate.set(
          key,
          [],
        );
      }


      bookingsByDate
        .get(
          key,
        )
        .push(
          booking,
        );
    },
  );


  const today =
    new Date();


  let selectedDate =
    new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );


  let visibleMonth =
    new Date(
      today.getFullYear(),
      today.getMonth(),
      1,
    );


  function renderSchedule() {
    const year =
      visibleMonth.getFullYear();

    const month =
      visibleMonth.getMonth();


    const firstDay =
      new Date(
        year,
        month,
        1,
      );


    const daysInMonth =
      new Date(
        year,
        month + 1,
        0,
      ).getDate();


    const firstWeekday =
      (
        firstDay.getDay() +
        6
      ) % 7;


    const calendarCells = [];


    for (
      let index = 0;
      index < firstWeekday;
      index += 1
    ) {
      calendarCells.push(`
        <div
          class="provider-calendar-day provider-calendar-empty"
        ></div>
      `);
    }


    for (
      let day = 1;
      day <= daysInMonth;
      day += 1
    ) {
      const date =
        new Date(
          year,
          month,
          day,
        );


      const key =
        dashboardDateKey(
          date,
        );


      const dayBookings =
        bookingsByDate.get(
          key,
        ) ?? [];


      const selected =
        dashboardSameDate(
          date,
          selectedDate,
        );


      const isToday =
        dashboardSameDate(
          date,
          today,
        );


      calendarCells.push(`
        <button
          type="button"
          class="
            provider-calendar-day
            ${
              selected
                ? 'selected'
                : ''
            }
            ${
              isToday
                ? 'today'
                : ''
            }
            ${
              dayBookings.length > 0
                ? 'has-bookings'
                : ''
            }
          "
          data-dashboard-date="${key}"
        >

          <span
            class="provider-calendar-day-number"
          >
            ${day}
          </span>

          ${
            dayBookings.length > 0
              ? `
                <span
                  class="provider-calendar-booking-count"
                >
                  ${dayBookings.length}
                </span>
              `
              : ''
          }

        </button>
      `);
    }


    const selectedKey =
      dashboardDateKey(
        selectedDate,
      );


    const selectedBookings =
      [
        ...(
          bookingsByDate.get(
            selectedKey,
          ) ?? []
        ),
      ]
        .sort(
          (a, b) =>
            a._scheduleStart -
            b._scheduleStart,
        );


    scheduleContainer.innerHTML = `

      <div class="provider-calendar">

        <div class="provider-calendar-header">

          <button
            type="button"
            class="secondary-button provider-calendar-navigation"
            id="provider-calendar-previous"
          >
            ←
          </button>


          <strong>
            ${escapeHtml(
              formatScheduleMonth(
                visibleMonth,
              ),
            )}
          </strong>


          <button
            type="button"
            class="secondary-button provider-calendar-navigation"
            id="provider-calendar-next"
          >
            →
          </button>

        </div>


        <div class="provider-calendar-weekdays">

          <span>Mon</span>
          <span>Tue</span>
          <span>Wed</span>
          <span>Thu</span>
          <span>Fri</span>
          <span>Sat</span>
          <span>Sun</span>

        </div>


        <div class="provider-calendar-grid">

          ${calendarCells.join('')}

        </div>

      </div>


      <div class="provider-schedule-agenda">

        <div class="provider-schedule-heading">

          <div>

            <p class="portal-label">
              SELECTED DATE
            </p>

            <h3>
              ${escapeHtml(
                formatScheduleDate(
                  selectedDate,
                ),
              )}
            </h3>

          </div>


          <span>
            ${selectedBookings.length}
            appointment${
              selectedBookings.length === 1
                ? ''
                : 's'
            }
          </span>

        </div>


        ${
          selectedBookings.length === 0
            ? `
              <div class="provider-dashboard-empty">

                <p>
                  No scheduled appointments
                  for this date.
                </p>

              </div>
            `
            : selectedBookings
                .map(
                  (booking) => {
                    const serviceLabels =
                      Array.isArray(
                        booking.serviceIds,
                      )
                        ? booking.serviceIds
                            .map(
                              (serviceId) =>
                                serviceNames.get(
                                  serviceId,
                                ) ||
                                formatDisplayName(
                                  serviceId,
                                ),
                            )
                            .join(', ')
                        : 'Service';


                    const technicianName =
                      technicianNames.get(
                        booking.technicianId,
                      ) ||
                      'Assigned Technician';


                    return `
                      <button
                        type="button"
                        class="provider-schedule-booking"
                        data-dashboard-booking-id="${escapeHtml(
                          booking.id,
                        )}"
                      >

                        <div
                          class="provider-schedule-booking-time"
                        >
                          ${escapeHtml(
                            formatScheduleTime(
                              booking
                                ._scheduleStart,
                            ),
                          )}

                          –

                          ${escapeHtml(
                            formatScheduleTime(
                              booking
                                ._scheduleEnd,
                            ),
                          )}
                        </div>


                        <div
                          class="provider-schedule-booking-info"
                        >

                          <strong>
                            ${escapeHtml(
                              serviceLabels,
                            )}
                          </strong>

                          <span>
                            ${escapeHtml(
                              technicianName,
                            )}
                          </span>

                        </div>


                        <span
                          class="provider-schedule-status"
                        >
                          ${escapeHtml(
                            formatStatus(
                              booking.status,
                            ),
                          )}
                        </span>

                      </button>
                    `;
                  },
                )
                .join('')
        }

      </div>
    `;


    scheduleContainer
      .querySelector(
        '#provider-calendar-previous',
      )
      .addEventListener(
        'click',
        () => {
          visibleMonth =
            new Date(
              year,
              month - 1,
              1,
            );


          selectedDate =
            new Date(
              visibleMonth.getFullYear(),
              visibleMonth.getMonth(),
              1,
            );


          renderSchedule();
        },
      );


    scheduleContainer
      .querySelector(
        '#provider-calendar-next',
      )
      .addEventListener(
        'click',
        () => {
          visibleMonth =
            new Date(
              year,
              month + 1,
              1,
            );


          selectedDate =
            new Date(
              visibleMonth.getFullYear(),
              visibleMonth.getMonth(),
              1,
            );


          renderSchedule();
        },
      );


    scheduleContainer
      .querySelectorAll(
        '[data-dashboard-date]',
      )
      .forEach(
        (button) => {
          button.addEventListener(
            'click',
            () => {
              const [
                dateYear,
                dateMonth,
                dateDay,
              ] =
                button.dataset
                  .dashboardDate
                  .split('-')
                  .map(Number);


              selectedDate =
                new Date(
                  dateYear,
                  dateMonth - 1,
                  dateDay,
                );


              renderSchedule();
            },
          );
        },
      );


    scheduleContainer
      .querySelectorAll(
        '[data-dashboard-booking-id]',
      )
      .forEach(
        (button) => {
          button.addEventListener(
            'click',
            () => {
              onOpenBooking?.(
                button.dataset
                  .dashboardBookingId,
              );
            },
          );
        },
      );
  }


  renderSchedule();
}


function bookingTimestampToDate(
  value,
) {
  if (
    value instanceof Date
  ) {
    return value;
  }


  const converted =
    value?.toDate?.();


  if (
    converted instanceof Date &&
    !Number.isNaN(
      converted.getTime(),
    )
  ) {
    return converted;
  }


  return null;
}


function dashboardDateKey(
  date,
) {
  return (
    String(
      date.getFullYear(),
    ) +
    '-' +
    String(
      date.getMonth() + 1,
    ).padStart(
      2,
      '0',
    ) +
    '-' +
    String(
      date.getDate(),
    ).padStart(
      2,
      '0',
    )
  );
}


function dashboardSameDate(
  first,
  second,
) {
  return (
    first.getFullYear() ===
      second.getFullYear() &&
    first.getMonth() ===
      second.getMonth() &&
    first.getDate() ===
      second.getDate()
  );
}


function formatScheduleMonth(
  date,
) {
  return new Intl.DateTimeFormat(
    'en-MY',
    {
      month: 'long',
      year: 'numeric',
    },
  ).format(
    date,
  );
}


function formatScheduleDate(
  date,
) {
  return new Intl.DateTimeFormat(
    'en-MY',
    {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    },
  ).format(
    date,
  );
}


function formatScheduleTime(
  date,
) {
  if (
    !(date instanceof Date)
  ) {
    return '--:--';
  }


  return (
    String(
      date.getHours(),
    ).padStart(
      2,
      '0',
    ) +
    ':' +
    String(
      date.getMinutes(),
    ).padStart(
      2,
      '0',
    )
  );
}

function minutesToTime(
  minutes,
) {
  const hours =
    Math.floor(
      Number(minutes) / 60,
    );

  const remainingMinutes =
    Number(minutes) % 60;

  return (
    String(hours)
      .padStart(2, '0') +
    ':' +
    String(remainingMinutes)
      .padStart(2, '0')
  );
}


function timeToMinutes(
  value,
) {
  if (
    typeof value !== 'string' ||
    !value.includes(':')
  ) {
    return 0;
  }

  const [
    hours,
    minutes,
  ] = value
    .split(':')
    .map(Number);

  return (
    hours * 60 +
    minutes
  );
}


function formatDisplayName(
  value,
) {
  return String(value ?? '')
    .replaceAll('_', ' ')
    .replace(
      /\b\w/g,
      (letter) =>
        letter.toUpperCase(),
    );
}


function saveProviderRoute(
  providerId,
  route,
) {
  localStorage.setItem(
    `homeassist:lastRoute:${providerId}`,
    route,
  );
}


function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

export {
  showProviderDashboardPage,
};