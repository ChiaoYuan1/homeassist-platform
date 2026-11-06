import {
  showAppMessage,
  confirmAppAction,
} from '../../utils/app-dialog.js';

import {
  formatStatus,
  getProviderBookings,
  updateProviderBookingStatus,
} from '../../services/provider-booking-service.js';

import {
  getProviderDashboardData,
} from '../../services/provider-dashboard-service.js';

import {
  getProviderTechnicians,
} from '../../services/provider-service.js';


async function showProviderBookingsPage(
  app,
  {
    providerId,
    providerName,
    onDashboard,
    onTeamAvailability,
    onAvailability,
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
              id="bookings-dashboard-button"
            >
              Dashboard
            </button>

            <button
              type="button"
              class="provider-nav-button active"
            >
              Bookings
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="bookings-team-button"
            >
              Team
            </button>

            <button
              type="button"
              class="provider-nav-button"
              id="bookings-availability-button"
            >
              Availability
            </button>

          </nav>

        </div>

        <button
          type="button"
          class="text-button"
          id="bookings-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <div>

            <p class="portal-label">
              BOOKING MANAGEMENT
            </p>

            <h1>
              Customer Bookings
            </h1>

            <p>
              Review customer service requests
              and update job progress.
            </p>

          </div>

        </div>


        <div
          id="provider-bookings-content"
          class="provider-dashboard-content"
        >
          <div class="provider-dashboard-loading">
            Loading bookings...
          </div>
        </div>

      </section>

    </main>
  `;


  document
    .querySelector(
      '#bookings-dashboard-button',
    )
    .addEventListener(
      'click',
      () => {
        onDashboard();
      },
    );


  document
    .querySelector(
      '#bookings-team-button',
    )
    .addEventListener(
      'click',
      () => {
        onTeamAvailability();
      },
    );


  document
    .querySelector(
      '#bookings-availability-button',
    )
    .addEventListener(
      'click',
      () => {
        onAvailability();
      },
    );


  document
    .querySelector(
      '#bookings-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  const content =
    document.querySelector(
      '#provider-bookings-content',
    );


  try {
    const [
      bookings,
      dashboardData,
      technicians,
    ] = await Promise.all([
      getProviderBookings(
        providerId,
      ),

      getProviderDashboardData(
        providerId,
      ),

      getProviderTechnicians(
        providerId,
      ),
    ]);


    const services =
      dashboardData?.services ?? [];


    const serviceNames =
      new Map(
        services.map(
          (service) => [
            service.id,
            service.name ||
              formatName(service.id),
          ],
        ),
      );


    const technicianNames =
      new Map(
        technicians.map(
          (technician) => [
            technician.id,
            technician.name ||
              'Technician',
          ],
        ),
      );

    if (bookings.length === 0) {
      content.innerHTML = `
        <section class="provider-dashboard-card">

          <p class="portal-label">
            BOOKINGS
          </p>

          <h2>
            No bookings yet
          </h2>

          <p>
            New customer booking requests
            will appear here.
          </p>

        </section>
      `;

      return;
    }


    const historyStatuses =
      new Set([
        'completed',
        'expired',
        'cancelled',
        'rejected',
      ]);


    const activeBookings =
      bookings
        .filter(
          (booking) =>
            !historyStatuses.has(
              booking.status,
            ),
        )
        .sort(
          compareActiveBookings,
        );


    content.innerHTML = `

      <section class="provider-bookings-group">

        <div class="provider-bookings-section-heading">

          <div>

            <p class="portal-label">
              CURRENT WORK
            </p>

            <h2>
              Active & Upcoming Bookings
            </h2>

            <p>
              Current jobs and upcoming
              customer appointments.
            </p>

          </div>


          <button
            type="button"
            class="provider-bookings-history-button"
            id="open-booking-history-button"
          >
            View Booking History
          </button>

        </div>


        ${
          activeBookings.length === 0
            ? `
              <div class="provider-dashboard-empty">

                <h3>
                  No active bookings
                </h3>

                <p>
                  There are currently no active
                  or upcoming appointments.
                </p>

              </div>
            `
            : activeBookings
                .map(
                  (booking) =>
                    buildBookingCard(
                      booking,
                      serviceNames,
                      technicianNames,
                    ),
                )
                .join('')
        }

      </section>
    `;
     document
      .querySelector(
        '#open-booking-history-button',
      )
      .addEventListener(
        'click',
        () => {
          showProviderBookingHistoryPage(
            app,
            {
              providerId,
              providerName,
              onDashboard,
              onTeamAvailability,
              onAvailability,
              onSignOut,
            },
          );
        },
      );

    content
      .querySelectorAll(
        '[data-booking-action]',
      )
      .forEach(
        (button) => {
          button.addEventListener(
            'click',
            async () => {
              const bookingId =
                button.dataset.bookingId;

              const status =
                button.dataset.bookingAction;


              await handleStatusUpdate(
                {
                  button,
                  providerId,
                  bookingId,
                  status,
                  app,
                  providerName,
                  onDashboard,
                  onTeamAvailability,
                  onAvailability,
                  onSignOut,
                },
              );
            },
          );
        },
      );

  const focusStorageKey =
    `homeassist:focusBooking:${providerId}`;


  const focusBookingId =
    sessionStorage.getItem(
      focusStorageKey,
    );


  if (focusBookingId) {
    sessionStorage.removeItem(
      focusStorageKey,
    );


    const bookingCard =
      Array.from(
        content.querySelectorAll(
          '[data-booking-card-id]',
        ),
      ).find(
        (card) =>
          card.dataset.bookingCardId ===
          focusBookingId,
      );


    if (bookingCard) {
      requestAnimationFrame(
        () => {
          bookingCard.scrollIntoView(
            {
              behavior: 'smooth',
              block: 'center',
            },
          );


          bookingCard.classList.add(
            'provider-booking-focus',
          );


          setTimeout(
            () => {
              bookingCard.classList.remove(
                'provider-booking-focus',
              );
            },
            1800,
          );
        },
      );
    }
  }

  } catch (error) {
    console.error(
      'Unable to load provider bookings:',
      error,
    );

    content.innerHTML = `
      <section class="provider-dashboard-card">

        <h2>
          Unable to load bookings
        </h2>

        <p>
          Please refresh the page
          and try again.
        </p>

      </section>
    `;
  }
}

function compareActiveBookings(
  first,
  second,
) {
  const priority = {
    inProgress: 0,
    arrived: 1,
    onTheWay: 2,
    pending: 3,
    accepted: 4,
  };


  const firstPriority =
    priority[first.status] ?? 99;

  const secondPriority =
    priority[second.status] ?? 99;


  if (
    firstPriority !==
    secondPriority
  ) {
    return (
      firstPriority -
      secondPriority
    );
  }


  return (
    getBookingTime(first) -
    getBookingTime(second)
  );
}


function getBookingTime(
  booking,
) {
  return (
    booking.appointmentStart
      ?.toDate?.()
      ?.getTime?.() ??
    0
  );
}

async function showProviderBookingHistoryPage(
  app,
  {
    providerId,
    providerName,
    onDashboard,
    onTeamAvailability,
    onAvailability,
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
              id="history-dashboard-button"
            >
              Dashboard
            </button>


            <button
              type="button"
              class="provider-nav-button active"
              id="history-bookings-button"
            >
              Bookings
            </button>


            <button
              type="button"
              class="provider-nav-button"
              id="history-team-button"
            >
              Team
            </button>


            <button
              type="button"
              class="provider-nav-button"
              id="history-availability-button"
            >
              Availability
            </button>

          </nav>

        </div>


        <button
          type="button"
          class="text-button"
          id="history-sign-out-button"
        >
          Sign Out
        </button>

      </aside>


      <section class="provider-dashboard-main">

        <div class="provider-dashboard-heading">

          <p class="portal-label">
            BOOKING MANAGEMENT
          </p>

          <h1>
            Booking History
          </h1>

          <p>
            Review previous customer
            booking records.
          </p>

        </div>


        <div
          id="provider-history-page-content"
          class="provider-dashboard-content"
        >

          <div class="provider-dashboard-loading">
            Loading booking history...
          </div>

        </div>

      </section>

    </main>
  `;


  const goBackToBookings =
    () => {
      showProviderBookingsPage(
        app,
        {
          providerId,
          providerName,
          onDashboard,
          onTeamAvailability,
          onAvailability,
          onSignOut,
        },
      );
    };


  document
    .querySelector(
      '#history-dashboard-button',
    )
    .addEventListener(
      'click',
      onDashboard,
    );


  document
    .querySelector(
      '#history-bookings-button',
    )
    .addEventListener(
      'click',
      goBackToBookings,
    );


  document
    .querySelector(
      '#history-team-button',
    )
    .addEventListener(
      'click',
      onTeamAvailability,
    );


  document
    .querySelector(
      '#history-availability-button',
    )
    .addEventListener(
      'click',
      onAvailability,
    );


  document
    .querySelector(
      '#history-sign-out-button',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );


  const content =
    document.querySelector(
      '#provider-history-page-content',
    );


  try {
    const [
      bookings,
      dashboardData,
      technicians,
    ] = await Promise.all([
      getProviderBookings(
        providerId,
      ),

      getProviderDashboardData(
        providerId,
      ),

      getProviderTechnicians(
        providerId,
      ),
    ]);


    const services =
      dashboardData?.services ?? [];


    const serviceNames =
      new Map(
        services.map(
          (service) => [
            service.id,

            service.name ||
              formatName(
                service.id,
              ),
          ],
        ),
      );


    const technicianNames =
      new Map(
        technicians.map(
          (technician) => [
            technician.id,

            technician.name ||
              'Technician',
          ],
        ),
      );


    const historyBookings =
      bookings.filter(
        (booking) =>
          [
            'completed',
            'expired',
            'cancelled',
            'rejected',
          ].includes(
            booking.status,
          ),
      );


    content.innerHTML = `

      <div class="provider-history-header">

        <div>

          <p class="portal-label">
            HISTORY
          </p>

          <h2>
            Previous Bookings
          </h2>

          <p>
            Select a category to review
            previous booking records.
          </p>

        </div>


        <button
          type="button"
          class="secondary-button provider-history-back-button"
          id="back-to-current-bookings-button"
        >
          ← Back to Bookings
        </button>

      </div>


      <div class="provider-history-tabs">

        <button
          type="button"
          class="provider-history-tab active"
          data-history-status="completed"
        >
          Completed
        </button>


        <button
          type="button"
          class="provider-history-tab"
          data-history-status="expired"
        >
          Expired
        </button>


        <button
          type="button"
          class="provider-history-tab"
          data-history-status="cancelled"
        >
          Cancelled
        </button>


        <button
          type="button"
          class="provider-history-tab"
          data-history-status="rejected"
        >
          Rejected
        </button>

      </div>


      <div
        id="provider-history-content"
        class="provider-history-content"
      ></div>
    `;


    document
      .querySelector(
        '#back-to-current-bookings-button',
      )
      .addEventListener(
        'click',
        goBackToBookings,
      );


    const historyContent =
      document.querySelector(
        '#provider-history-content',
      );


    const historyTabs =
      Array.from(
        document.querySelectorAll(
          '.provider-history-tab',
        ),
      );


    function renderHistoryStatus(
      status,
    ) {
      historyTabs.forEach(
        (tab) => {
          tab.classList.toggle(
            'active',
            tab.dataset.historyStatus ===
              status,
          );
        },
      );


      const filteredBookings =
        historyBookings
          .filter(
            (booking) =>
              booking.status ===
              status,
          )
          .sort(
            (first, second) =>
              getBookingTime(second) -
              getBookingTime(first),
          );


      if (
        filteredBookings.length === 0
      ) {
        historyContent.innerHTML = `
          <div class="provider-history-empty">

            <h3>
              No ${escapeHtml(
                formatStatus(
                  status,
                ),
              )} bookings
            </h3>

            <p>
              There are currently no bookings
              in this history category.
            </p>

          </div>
        `;

        return;
      }


      historyContent.innerHTML =
        filteredBookings
          .map(
            (booking) =>
              buildBookingCard(
                booking,
                serviceNames,
                technicianNames,
              ),
          )
          .join('');
    }


    historyTabs.forEach(
      (tab) => {
        tab.addEventListener(
          'click',
          () => {
            renderHistoryStatus(
              tab.dataset.historyStatus,
            );
          },
        );
      },
    );


    renderHistoryStatus(
      'completed',
    );

  } catch (error) {
    console.error(
      'Unable to load booking history:',
      error,
    );


    content.innerHTML = `
      <div class="provider-dashboard-empty">

        <h2>
          Unable to load booking history
        </h2>

        <p>
          Please return to Bookings
          and try again.
        </p>

      </div>
    `;
  }
}

function buildBookingCard(
  booking,
  serviceNames,
  technicianNames,
) {
  const appointmentStart =
    booking.appointmentStart
      ?.toDate?.();

  const appointmentEnd =
    booking.appointmentEnd
      ?.toDate?.();


  const services =
    Array.isArray(
      booking.serviceIds,
    )
      ? booking.serviceIds
          .map(
            (serviceId) =>
              serviceNames.get(
                serviceId,
              ) ||
              formatName(
                serviceId,
              ),
          )
      : [];


  const technicianName =
    technicianNames.get(
      booking.technicianId,
    ) ||
    'Assigned Technician';


  const problemDetailsHtml =
    buildProblemDetails(
      booking,
      serviceNames,
    );


  return `
    <section
      class="provider-dashboard-card provider-booking-card"
      data-booking-card-id="${escapeAttribute(
        booking.id,
      )}"
    >

      <div
        style="
          display: flex;
          justify-content: space-between;
          gap: 16px;
          align-items: flex-start;
        "
      >

        <div>

          <p class="portal-label">
            ${escapeHtml(
              formatStatus(
                booking.status,
              ),
            )}
          </p>

          <h2>
            ${escapeHtml(
              services.join(', ') ||
              formatName(
                booking.categoryId,
              ),
            )}
          </h2>

        </div>

        <strong>
          ${escapeHtml(
            formatStatus(
              booking.status,
            ),
          )}
        </strong>

      </div>


      <div
        class="provider-dashboard-meta"
        style="
          margin-top: 18px;
        "
      >

        <span>
          ${escapeHtml(
            formatAppointment(
              appointmentStart,
              appointmentEnd,
            ),
          )}
        </span>

        <span>
          Technician:
          ${escapeHtml(
            technicianName,
          )}
        </span>

      </div>


      <div
        style="
          margin-top: 20px;
          display: grid;
          gap: 12px;
        "
      >

        <div>
          <strong>
            Service Address
          </strong>

          <p>
            ${escapeHtml(
              booking.address ||
              'No address provided.',
            )}
          </p>
        </div>

        ${problemDetailsHtml}

        ${
          booking.primaryIssue
            ? `
              <div>
                <strong>
                  Primary Issue
                </strong>

                <p>
                  ${escapeHtml(
                    booking.primaryIssue,
                  )}
                </p>
              </div>
            `
            : ''
        }


        ${
          booking.gasBrandPreference
            ? `
              <div>
                <strong>
                  Gas Brand Preference
                </strong>

                <p>
                  ${escapeHtml(
                    booking.gasBrandPreference,
                  )}
                </p>
              </div>
            `
            : ''
        }

      </div>


      ${buildBookingActions(
        booking,
      )}

    </section>
  `;
}


function buildProblemDetails(
  booking,
  serviceNames,
) {
  const problemDetails =
    Array.isArray(
      booking.problemDetails,
    )
      ? booking.problemDetails
      : [];


  // New bookings
  if (problemDetails.length > 0) {
    return `
      <div>
        <strong>
          Problems
        </strong>

        <div
          style="
            margin-top: 12px;
            display: grid;
            gap: 14px;
          "
        >
          ${problemDetails
            .map(
              (problem, index) => {
                const serviceName =
                  problem.serviceName ||
                  serviceNames.get(
                    problem.serviceId,
                  ) ||
                  formatName(
                    problem.serviceId,
                  ) ||
                  'Problem';


                const description =
                  String(
                    problem.description ??
                      '',
                  ).trim();


                const photoUrls =
                  Array.isArray(
                    problem.photoUrls,
                  )
                    ? problem.photoUrls.filter(
                        (url) =>
                          String(
                            url ?? '',
                          ).trim(),
                      )
                    : [];


                const problemLabel =
                  problem.isPrimary ||
                  index === 0
                    ? 'Main Problem'
                    : `Additional Problem ${index}`;


                return `
                  <div
                    style="
                      border: 1px solid #e5e7eb;
                      border-radius: 12px;
                      padding: 16px;
                    "
                  >

                    <p
                      class="portal-label"
                      style="
                        margin: 0 0 8px;
                      "
                    >
                      ${escapeHtml(
                        problemLabel,
                      )}
                    </p>


                    <strong>
                      ${escapeHtml(
                        serviceName,
                      )}
                    </strong>


                    <div
                      style="
                        margin-top: 12px;
                      "
                    >
                      <strong>
                        Problem Details
                      </strong>

                      <p>
                        ${escapeHtml(
                          description ||
                            'No additional details provided.',
                        )}
                      </p>
                    </div>


                    <div
                      style="
                        margin-top: 12px;
                      "
                    >
                      <strong>
                        Photos
                      </strong>

                      ${
                        photoUrls.length > 0
                          ? `
                              <div
                                style="
                                  margin-top: 8px;
                                  display: flex;
                                  gap: 10px;
                                  flex-wrap: wrap;
                                "
                              >
                                ${photoUrls
                                  .map(
                                    (url) => `
                                      <a
                                        href="${escapeAttribute(
                                          url,
                                        )}"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                      >
                                        <img
                                          src="${escapeAttribute(
                                            url,
                                          )}"
                                          alt="Problem photo"
                                          style="
                                            width: 96px;
                                            height: 96px;
                                            object-fit: cover;
                                            border-radius: 10px;
                                            border: 1px solid #e5e7eb;
                                          "
                                        >
                                      </a>
                                    `,
                                  )
                                  .join('')}
                              </div>
                            `
                          : `
                              <p>
                                No photos provided.
                              </p>
                            `
                      }

                    </div>

                  </div>
                `;
              },
            )
            .join('')}
        </div>
      </div>
    `;
  }


  // Old bookings
  return `
    <div>
      <strong>
        Problem Description
      </strong>

      <p>
        ${escapeHtml(
          booking.problemDescription ||
            'No description provided.',
        )}
      </p>
    </div>


    ${
      booking.primaryIssue
        ? `
            <div>
              <strong>
                Primary Issue
              </strong>

              <p>
                ${escapeHtml(
                  booking.primaryIssue,
                )}
              </p>
            </div>
          `
        : ''
    }
  `;
}

function buildBookingActions(
  booking,
) {
  switch (
    booking.status
  ) {
    case 'pending':
      return `
        <div
          style="
            margin-top: 22px;
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
          "
        >

          <button
            type="button"
            class="primary-button"
            data-booking-action="accepted"
            data-booking-id="${escapeAttribute(
              booking.id,
            )}"
          >
            Accept Booking
          </button>

          <button
            type="button"
            class="secondary-button"
            data-booking-action="rejected"
            data-booking-id="${escapeAttribute(
              booking.id,
            )}"
          >
            Reject Booking
          </button>

        </div>
      `;


    case 'accepted':
      return actionButton(
        booking.id,
        'onTheWay',
        'Mark as On the Way',
      );


    case 'onTheWay':
      return actionButton(
        booking.id,
        'arrived',
        'Mark as Arrived',
      );


    case 'arrived':
      return actionButton(
        booking.id,
        'inProgress',
        'Start Job',
      );


    case 'inProgress':
      return actionButton(
        booking.id,
        'completed',
        'Complete Job',
      );


    case 'completed':
      return `
        <p
          style="
            margin-top: 20px;
          "
        >
          This booking has been completed.
        </p>
      `;

    case 'expired':
      return `
        <p
          style="
            margin-top: 20px;
          "
        >
          This booking has expired.
        </p>
      `;
    
    case 'rejected':
      return `
        <p
          style="
            margin-top: 20px;
          "
        >
          This booking was rejected.
        </p>
      `;


    case 'cancelled':
      return `
        <p
          style="
            margin-top: 20px;
          "
        >
          This booking was cancelled.
        </p>
      `;


    default:
      return '';
  }
}


function actionButton(
  bookingId,
  nextStatus,
  label,
) {
  return `
    <div
      style="
        margin-top: 22px;
      "
    >

      <button
        type="button"
        class="primary-button"
        data-booking-action="${escapeAttribute(
          nextStatus,
        )}"
        data-booking-id="${escapeAttribute(
          bookingId,
        )}"
      >
        ${escapeHtml(label)}
      </button>

    </div>
  `;
}

async function handleStatusUpdate({
  button,
  providerId,
  bookingId,
  status,
  app,
  providerName,
  onDashboard,
  onTeamAvailability,
  onAvailability,
  onSignOut,
}) {
  if (
    status === 'rejected'
  ) {
    const confirmed = await confirmAppAction({
      title: 'Reject Booking?',
      message: 'Are you sure you want to reject this booking request?',
      confirmLabel: 'Reject Booking',
      destructive: true,
    });
  }


  const oldText =
    button.textContent;


  button.disabled = true;

  button.textContent =
    'Updating...';


  try {
    await updateProviderBookingStatus({
      providerId,
      bookingId,
      status,
    });


    await showProviderBookingsPage(
      app,
      {
        providerId,
        providerName,
        onDashboard,
        onTeamAvailability,
        onAvailability,
        onSignOut,
      },
    );

  } catch (error) {
    console.error(
      'Unable to update booking:',
      error,
    );

    await showAppMessage(
      'Unable to Update Booking',
      error.message || 'Unable to update booking.',
    );

    button.disabled = false;

    button.textContent =
      oldText;
  }
}

function formatAppointment(
  start,
  end,
) {
  if (!start) {
    return 'Appointment time unavailable';
  }

  const date =
    start.toLocaleDateString(
      'en-MY',
      {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
      },
    );


  const startTime =
    start.toLocaleTimeString(
      'en-MY',
      {
        hour: 'numeric',
        minute: '2-digit',
      },
    );


  const endTime =
    end
      ? end.toLocaleTimeString(
          'en-MY',
          {
            hour: 'numeric',
            minute: '2-digit',
          },
        )
      : '';


  return endTime
    ? `${date}, ${startTime} – ${endTime}`
    : `${date}, ${startTime}`;
}


function formatName(
  value,
) {
  return String(
    value ?? '',
  )
    .split('_')
    .filter(Boolean)
    .map(
      (word) =>
        word.charAt(0).toUpperCase() +
        word.slice(1),
    )
    .join(' ');
}


function escapeHtml(
  value,
) {
  return String(
    value ?? '',
  )
    .replaceAll(
      '&',
      '&amp;',
    )
    .replaceAll(
      '<',
      '&lt;',
    )
    .replaceAll(
      '>',
      '&gt;',
    )
    .replaceAll(
      '"',
      '&quot;',
    )
    .replaceAll(
      "'",
      '&#039;',
    );
}


function escapeAttribute(
  value,
) {
  return escapeHtml(
    value,
  );
}


export {
  showProviderBookingsPage,
};