
import { jsPDF } from 'jspdf';

function bookingDate(booking) {
  function convert(value) {
    if (!value) {
      return null;
    }

    let date;

    if (typeof value.toDate === 'function') {
      date = value.toDate();
    } else if (typeof value.seconds === 'number') {
      date = new Date(value.seconds * 1000);
    } else if (typeof value._seconds === 'number') {
      date = new Date(value._seconds * 1000);
    } else {
      date = new Date(value);
    }

    return Number.isNaN(date.getTime())
      ? null
      : date;
  }

  return convert(booking.createdAt) ??
    convert(booking.appointmentStart);
}

function monthKey(date) {
  return `${date.getFullYear()}-${String(
    date.getMonth() + 1,
  ).padStart(2, '0')}`;
}

function mondayOf(date) {
  const monday = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
  );

  monday.setDate(
    monday.getDate() -
    (monday.getDay() + 6) % 7,
  );

  return monday;
}

function dayKey(date) {
  return `${monthKey(date)}-${String(
    date.getDate(),
  ).padStart(2, '0')}`;
}

function monthLabel(key) {
  const [year, month] = key.split('-').map(Number);

  return new Date(year, month - 1, 1)
    .toLocaleDateString('en-MY', {
      month: 'short',
      year: 'numeric',
    });
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function serviceName(id, names) {
  return names.get(id) ||
    String(id)
      .replaceAll('_', ' ')
      .replace(
        /\b\w/g,
        (letter) => letter.toUpperCase(),
      );
}

// Standard jsPDF fonts do not support every Unicode character.
function pdfText(value) {
  return String(value ?? '')
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/[\u201C\u201D]/g, '"')
    .replace(/[\u2013\u2014]/g, '-')
    .replace(/[\u2022\u00B7]/g, '-')
    .replace(/\s+/g, ' ')
    .trim();
}

// Generate a formatted analytics PDF using existing dashboard data.
function downloadProviderAnalyticsPdf(analytics, providerName = '') {
  const doc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: 'a4',
  });

  const PAGE_HEIGHT = 297;
  const LEFT = 16;
  const RIGHT = 194;
  const CONTENT_WIDTH = RIGHT - LEFT;
  const BOTTOM_LIMIT = 274;

  const BLUE = [37, 99, 235];
  const NAVY = [15, 23, 42];
  const MUTED = [100, 116, 139];
  const BORDER = [226, 232, 240];
  const PALE = [248, 250, 252];
  const BLUE_PALE = [239, 246, 255];

  let y = 16;

  function setTextColor(rgb = NAVY) {
    doc.setTextColor(...rgb);
  }

  function setFillColor(rgb) {
    doc.setFillColor(...rgb);
  }

  function addPage() {
    doc.addPage();
    y = 19;
  }

  function needSpace(height) {
    if (y + height > BOTTOM_LIMIT) {
      addPage();
    }
  }

  function wrap(value, maxWidth, fontSize = 9, weight = 'normal') {
    doc.setFont('helvetica', weight);
    doc.setFontSize(fontSize);
    return doc.splitTextToSize(pdfText(value), maxWidth);
  }

  function textLine(
    value,
    x,
    atY,
    fontSize = 9,
    weight = 'normal',
    color = NAVY,
  ) {
    doc.setFont('helvetica', weight);
    doc.setFontSize(fontSize);
    setTextColor(color);
    doc.text(pdfText(value), x, atY);
  }

  function paragraph(
    value,
    width = CONTENT_WIDTH,
    fontSize = 8.5,
  ) {
    const lines = wrap(value, width, fontSize);
    needSpace(lines.length * 4.5 + 3);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(fontSize);
    setTextColor(MUTED);
    doc.text(lines, LEFT, y);

    y += lines.length * 4.5 + 4;
  }

  function heading(value) {
    needSpace(15);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    setTextColor(NAVY);
    doc.text(pdfText(value), LEFT, y);

    y += 8;
  }

  function separator() {
    doc.setDrawColor(...BORDER);
    doc.setLineWidth(0.25);
    doc.line(LEFT, y, RIGHT, y);

    y += 6;
  }

  function metricCard(x, top, width, title, value) {
    setFillColor(PALE);
    doc.setDrawColor(...BORDER);
    doc.roundedRect(
      x,
      top,
      width,
      25,
      2.5,
      2.5,
      'FD',
    );

    textLine(
      title,
      x + 5,
      top + 8,
      8,
      'normal',
      MUTED,
    );

    const valueLines = wrap(
      value,
      width - 10,
      13,
      'bold',
    );

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(13);
    setTextColor(NAVY);

    doc.text(
      valueLines.slice(0, 2),
      x + 5,
      top + 16.5,
    );
  }

  function tableHeader(columns) {
    needSpace(10);

    setFillColor(BLUE_PALE);
    doc.rect(
      LEFT,
      y,
      CONTENT_WIDTH,
      9,
      'F',
    );

    let x = LEFT + 3;

    columns.forEach(({ label, width }) => {
      textLine(
        label,
        x,
        y + 6,
        8,
        'bold',
        NAVY,
      );

      x += width;
    });

    y += 9;
  }

  function tableRow(columns, values) {
    const linesByColumn = values.map(
      (value, index) =>
        wrap(
          value,
          columns[index].width - 6,
          8,
        ),
    );

    const rowHeight = Math.max(
      9,
      ...linesByColumn.map(
        (lines) => lines.length * 4.2 + 3,
      ),
    );

    needSpace(rowHeight);

    let x = LEFT + 3;

    linesByColumn.forEach((lines, index) => {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      setTextColor(NAVY);
      doc.text(lines, x, y + 5.5);

      x += columns[index].width;
    });

    doc.setDrawColor(...BORDER);
    doc.setLineWidth(0.2);
    doc.line(
      LEFT,
      y + rowHeight,
      RIGHT,
      y + rowHeight,
    );

    y += rowHeight;
  }

  const generatedAt = new Date();

  doc.setProperties({
    title: 'HomeAssist - Provider Analytics Report',
    subject: 'Company-wide service demand and technician activity',
    author: 'HomeAssist',
    keywords: 'HomeAssist, analytics, booking demand, technician activity',
  });

  // Report header
  setFillColor(BLUE);
  doc.roundedRect(
    LEFT,
    y,
    13,
    13,
    2.5,
    2.5,
    'F',
  );

  textLine(
    'H',
    LEFT + 4,
    y + 9.4,
    13,
    'bold',
    [255, 255, 255],
  );

  textLine(
    'HomeAssist',
    LEFT + 18,
    y + 5.5,
    15,
    'bold',
  );

  textLine(
    'PROVIDER ANALYTICS REPORT',
    LEFT + 18,
    y + 11.5,
    9,
    'bold',
    BLUE,
  );

  y += 22;

  if (providerName) {
    paragraph(`Provider: ${providerName}`);
  }

  paragraph(
    `Generated: ${generatedAt.toLocaleString('en-MY', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })}. Company-wide data across all branches, based on currently loaded booking records.`,
  );

  const demandPeriod =
    analytics.selectedMonth === 'all'
      ? 'All recorded months'
      : monthLabel(analytics.selectedMonth);

  const trendPeriod =
    analytics.trendPeriod === 'week'
      ? 'Last 12 weeks'
      : 'Last 12 months';

  setFillColor(BLUE_PALE);

  doc.roundedRect(
    LEFT,
    y,
    CONTENT_WIDTH,
    15,
    2,
    2,
    'F',
  );

  textLine(
    `Service demand: ${demandPeriod}`,
    LEFT + 5,
    y + 5.7,
    8,
    'bold',
  );

  textLine(
    `Booking trend: ${trendPeriod}`,
    LEFT + 5,
    y + 11.2,
    8,
    'bold',
  );

  y += 23;

  // Booking overview
  heading('Booking overview');

  const cardGap = 5;
  const cardWidth =
    (CONTENT_WIDTH - cardGap) / 2;

  metricCard(
    LEFT,
    y,
    cardWidth,
    'Total bookings',
    analytics.totalCount,
  );

  metricCard(
    LEFT + cardWidth + cardGap,
    y,
    cardWidth,
    'Completed jobs',
    analytics.completedCount,
  );

  y += 30;

  metricCard(
    LEFT,
    y,
    cardWidth,
    'Active bookings',
    analytics.activeCount,
  );

  metricCard(
    LEFT + cardWidth + cardGap,
    y,
    cardWidth,
    'Peak month (last 12)',
    analytics.peakLabel,
  );

  y += 35;

  // Most requested services
  heading('Most requested services');

  paragraph(
    `Service demand period: ${demandPeriod}. Each selected service is counted once per booking.`,
  );

  if (analytics.popular.length === 0) {
    paragraph(
      'No service requests were recorded for the selected period.',
    );
  } else {
    const serviceColumns = [
      {
        label: 'Service',
        width: 145,
      },
      {
        label: 'Requests',
        width: 33,
      },
    ];

    tableHeader(serviceColumns);

    analytics.popular.forEach(([id, count]) => {
      tableRow(
        serviceColumns,
        [
          serviceName(
            id,
            analytics.serviceNames,
          ),
          String(count),
        ],
      );
    });

    y += 6;
  }

  // Booking demand chart
  needSpace(88);
  heading('Booking demand');

  paragraph(
    `${trendPeriod}: number of booking requests created per period.`,
  );

  const chartHeight = 46;
  const chartTop = y + 3;
  const chartBottom = chartTop + chartHeight;
  const chartLeft = LEFT + 8;
  const chartWidth = CONTENT_WIDTH - 11;

  const chartMax = Math.max(
    1,
    ...analytics.periodCounts.values(),
  );

  doc.setDrawColor(...BORDER);
  doc.setLineWidth(0.35);

  doc.line(
    chartLeft,
    chartBottom,
    RIGHT,
    chartBottom,
  );

  const count = analytics.periods.length;

  const groupWidth =
    chartWidth / Math.max(1, count);

  const barWidth = Math.max(
    3,
    Math.min(
      8,
      groupWidth * 0.52,
    ),
  );

  analytics.periods.forEach((period, index) => {
    const requests =
      analytics.periodCounts.get(period.key) || 0;

    const columnHeight =
      requests === 0
        ? 0
        : Math.max(
            2,
            (requests / chartMax) *
              (chartHeight - 9),
          );

    const x =
      chartLeft +
      index * groupWidth +
      (groupWidth - barWidth) / 2;

    if (columnHeight > 0) {
      setFillColor(BLUE);

      doc.rect(
        x,
        chartBottom - columnHeight,
        barWidth,
        columnHeight,
        'F',
      );
    }

    const centre = x + barWidth / 2;

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7);
    setTextColor(NAVY);

    doc.text(
      String(requests),
      centre,
      chartBottom - columnHeight - 2,
      {
        align: 'center',
      },
    );

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.3);
    setTextColor(MUTED);

    doc.text(
      pdfText(period.label),
      centre,
      chartBottom + 5,
      {
        align: 'center',
        angle: 45,
      },
    );
  });

  y = chartBottom + 25;

  // Technician completion statistics
  heading('Most completed jobs by service');

  paragraph(
    'Shows the highest completed-job count for each service across all branches. It measures workload, not service quality. Ties are displayed together.',
  );

  if (analytics.technicianRows.length === 0) {
    paragraph(
      'No completed jobs assigned to technicians yet.',
    );
  } else {
    const columns = [
      {
        label: 'Service',
        width: 62,
      },
      {
        label: 'Technician(s)',
        width: 90,
      },
      {
        label: 'Jobs',
        width: 26,
      },
    ];

    tableHeader(columns);

    analytics.technicianRows.forEach((row) => {
      tableRow(
        columns,
        [
          row.name,
          row.leaders.join(', '),
          String(row.completed),
        ],
      );
    });

    y += 7;
  }

  separator();

  // Calculation explanations
  heading('Calculation notes');

  paragraph(
    'Demand includes submitted requests that were later rejected or cancelled. Multi-service bookings contribute once to the count of each selected service. Date-based analysis uses the booking creation date where available, otherwise the appointment date.',
  );

  paragraph(
    'The service-demand month applies only to Most Requested Services. The booking-demand chart covers the latest 12 weeks or months independently of that selection. Overview counts cover all loaded bookings.',
  );

  if (analytics.undatedCount > 0) {
    paragraph(
      `${analytics.undatedCount} booking(s) without usable dates were excluded from time-based charts, but remain included in overall booking totals.`,
    );
  }

  paragraph(
    'This is a snapshot of the records loaded when the provider dashboard opened or last refreshed. Changes made afterwards require a dashboard refresh before export.',
  );

  // Page numbers and footer
  const totalPages = doc.getNumberOfPages();

  for (
    let page = 1;
    page <= totalPages;
    page += 1
  ) {
    doc.setPage(page);
    doc.setDrawColor(...BORDER);
    doc.setLineWidth(0.3);

    doc.line(
      LEFT,
      PAGE_HEIGHT - 17,
      RIGHT,
      PAGE_HEIGHT - 17,
    );

    textLine(
      'HomeAssist - Company Analytics',
      LEFT,
      PAGE_HEIGHT - 10,
      7,
      'normal',
      MUTED,
    );

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    setTextColor(MUTED);

    doc.text(
      `Page ${page} of ${totalPages}`,
      RIGHT,
      PAGE_HEIGHT - 10,
      {
        align: 'right',
      },
    );
  }

  const dateStamp =
    `${generatedAt.getFullYear()}-${String(
      generatedAt.getMonth() + 1,
    ).padStart(2, '0')}-${String(
      generatedAt.getDate(),
    ).padStart(2, '0')}`;

  const filename =
    `HomeAssist_Provider_Analytics_${dateStamp}_${
      analytics.trendPeriod === 'week'
        ? 'Weekly'
        : 'Monthly'
    }.pdf`;

  doc.save(filename);
}

function setupProviderAnalytics({
  container,
  bookings = [],
  services = [],
  technicians = [],
}) {
  if (!container) {
    return;
  }

  const section = document.createElement('section');

  section.className =
    'provider-dashboard-card provider-analytics';

  section.innerHTML = `
    <p class="portal-label">
      COMPANY ANALYTICS
    </p>

    <h2>
      Service Demand & Technician Activity
    </h2>

    <p>
      Company-wide insights across all branches.
      Based on actual booking records.
    </p>

    <div class="provider-analytics-controls">
      <label for="analytics-service-month">
        Service demand
      </label>

      <select
        id="analytics-service-month"
        aria-label="Service demand month"
      ></select>

      <label for="analytics-trend-period">
        Booking trend
      </label>

      <select
        id="analytics-trend-period"
        aria-label="Booking trend period"
      >
        <option value="week">
          Weekly
        </option>

        <option value="month">
          Monthly
        </option>
      </select>

      <button
        type="button"
        id="download-analytics-report"
        class="secondary-button"
        style="margin-left: auto; white-space: nowrap;"
      >
        Download Report (PDF)
      </button>
    </div>

    <p
      id="analytics-export-message"
      class="provider-analytics-footnote"
      role="status"
      aria-live="polite"
    ></p>

    <div
      id="provider-analytics-results"
      aria-live="polite"
    ></div>
  `;

  // Insert analytics before the Booking Calendar.
  const schedule = container.querySelector(
    '#provider-dashboard-schedule',
  );

  const scheduleCard = schedule?.closest(
    '.provider-dashboard-card',
  );

  if (scheduleCard) {
    scheduleCard.before(section);
  } else {
    container.append(section);
  }

  const monthSelect = section.querySelector(
    '#analytics-service-month',
  );

  const trendSelect = section.querySelector(
    '#analytics-trend-period',
  );

  const results = section.querySelector(
    '#provider-analytics-results',
  );

  const downloadButton = section.querySelector(
    '#download-analytics-report',
  );

  const exportMessage = section.querySelector(
    '#analytics-export-message',
  );

  const datedBookings = bookings.map((booking) => ({
    ...booking,
    _analyticsDate: bookingDate(booking),
  }));

  const serviceNames = new Map(
    services.map((service) => [
      service.id,
      service.name || service.id,
    ]),
  );

  const technicianNames = new Map(
    technicians.map((technician) => [
      technician.id,
      technician.name || 'Unnamed technician',
    ]),
  );

  const monthOptions = [
    ...new Set([
      monthKey(new Date()),
      ...datedBookings
        .filter((booking) => booking._analyticsDate)
        .map((booking) =>
          monthKey(booking._analyticsDate),
        ),
    ]),
  ].sort().reverse();

  monthSelect.innerHTML = `
    <option value="all">
      All months
    </option>

    ${monthOptions
      .map(
        (key) => `
          <option value="${key}">
            ${escapeHtml(monthLabel(key))}
          </option>
        `,
      )
      .join('')}
  `;

  const today = new Date();

  const months = Array.from(
    { length: 12 },
    (_, index) => {
      const date = new Date(
        today.getFullYear(),
        today.getMonth() - (11 - index),
        1,
      );

      return {
        key: monthKey(date),
        label: date.toLocaleDateString('en-MY', {
          month: 'short',
          year: '2-digit',
        }),
      };
    },
  );

  const weeks = Array.from(
    { length: 12 },
    (_, index) => {
      const date = mondayOf(today);

      date.setDate(
        date.getDate() - 7 * (11 - index),
      );

      return {
        key: dayKey(date),
        label: date.toLocaleDateString('en-MY', {
          day: 'numeric',
          month: 'short',
        }),
      };
    },
  );

  let currentAnalytics = null;

  function render() {
    const selectedMonth = monthSelect.value;

    // Count service requests for the selected month.
    const filtered = datedBookings.filter(
      (booking) =>
        booking._analyticsDate &&
        (
          selectedMonth === 'all' ||
          monthKey(booking._analyticsDate) ===
            selectedMonth
        ),
    );

    const requestedServices = new Map();

    filtered.forEach((booking) => {
      const ids = new Set(
        Array.isArray(booking.serviceIds)
          ? booking.serviceIds
          : [],
      );

      ids.forEach((id) => {
        requestedServices.set(
          id,
          (requestedServices.get(id) || 0) + 1,
        );
      });
    });

    const popular = [
      ...requestedServices.entries(),
    ].sort(
      (a, b) => b[1] - a[1],
    );

    const maxServiceCount = Math.max(
      1,
      ...popular.map(([, count]) => count),
    );

    // Calculate weekly or monthly booking trends.
    const periods =
      trendSelect.value === 'week'
        ? weeks
        : months;

    const periodCounts = new Map(
      periods.map((period) => [
        period.key,
        0,
      ]),
    );

    datedBookings.forEach((booking) => {
      if (!booking._analyticsDate) {
        return;
      }

      const key =
        trendSelect.value === 'week'
          ? dayKey(
              mondayOf(booking._analyticsDate),
            )
          : monthKey(booking._analyticsDate);

      if (periodCounts.has(key)) {
        periodCounts.set(
          key,
          periodCounts.get(key) + 1,
        );
      }
    });

    const maxPeriodCount = Math.max(
      1,
      ...periodCounts.values(),
    );

    // Identify the month with highest demand.
    const lastYearCounts = new Map(
      months.map((item) => [
        item.key,
        0,
      ]),
    );

    datedBookings.forEach((booking) => {
      if (!booking._analyticsDate) {
        return;
      }

      const key = monthKey(
        booking._analyticsDate,
      );

      if (lastYearCounts.has(key)) {
        lastYearCounts.set(
          key,
          lastYearCounts.get(key) + 1,
        );
      }
    });

    const peak = [
      ...lastYearCounts.entries(),
    ].sort(
      (a, b) => b[1] - a[1],
    )[0];

    const peakLabel =
      peak && peak[1] > 0
        ? `${monthLabel(peak[0])} (${peak[1]})`
        : 'No requests yet';

    // Completed jobs per technician and service.
    const completed = datedBookings.filter(
      (booking) =>
        booking.status === 'completed',
    );

    const technicianByService = new Map();

    completed.forEach((booking) => {
      if (!booking.technicianId) {
        return;
      }

      const serviceIds = new Set(
        Array.isArray(booking.serviceIds)
          ? booking.serviceIds
          : [],
      );

      for (const id of serviceIds) {
        if (!technicianByService.has(id)) {
          technicianByService.set(
            id,
            new Map(),
          );
        }

        const counts =
          technicianByService.get(id);

        counts.set(
          booking.technicianId,
          (counts.get(booking.technicianId) || 0) + 1,
        );
      }
    });

    const technicianRows = [
      ...technicianByService.entries(),
    ]
      .map(([id, counts]) => {
        const best = Math.max(
          ...counts.values(),
        );

        const leaders = [
          ...counts.entries(),
        ]
          .filter(
            ([, count]) => count === best,
          )
          .map(
            ([technicianId]) =>
              technicianNames.get(technicianId) ||
              'Unknown technician',
          );

        return {
          name: serviceName(
            id,
            serviceNames,
          ),
          leaders,
          completed: best,
        };
      })
      .sort(
        (a, b) =>
          b.completed - a.completed,
      );

    // Overview statistics
    const completedCount = bookings.filter(
      (booking) =>
        booking.status === 'completed',
    ).length;

    const activeStatuses = new Set([
      'pending',
      'accepted',
      'onTheWay',
      'arrived',
      'inProgress',
    ]);

    const activeCount = bookings.filter(
      (booking) =>
        activeStatuses.has(booking.status),
    ).length;

    const datedCount = datedBookings.filter(
      (booking) =>
        booking._analyticsDate,
    ).length;

    // Both the dashboard and PDF use the same data.
    currentAnalytics = {
      selectedMonth,
      trendPeriod: trendSelect.value,
      totalCount: bookings.length,
      completedCount,
      activeCount,
      peakLabel,
      popular,
      serviceNames,
      periods,
      periodCounts,
      technicianRows,
      undatedCount:
        bookings.length - datedCount,
    };

    results.innerHTML = `
      <div class="provider-analytics-stats">
        <div>
          <span>Total bookings</span>
          <strong>${bookings.length}</strong>
        </div>

        <div>
          <span>Completed jobs</span>
          <strong>${completedCount}</strong>
        </div>

        <div>
          <span>Active bookings</span>
          <strong>${activeCount}</strong>
        </div>

        <div>
          <span>Peak month (last 12)</span>
          <strong>
            ${escapeHtml(peakLabel)}
          </strong>
        </div>
      </div>

      <div class="provider-analytics-grid">
        <div class="provider-analytics-panel">
          <h3>
            Most Requested Services
          </h3>

          <p>
            ${
              selectedMonth === 'all'
                ? 'All recorded months'
                : escapeHtml(
                    monthLabel(selectedMonth),
                  )
            }
          </p>

          ${
            popular.length === 0
              ? `
                <p class="provider-analytics-empty">
                  No service requests for this period.
                </p>
              `
              : popular
                  .map(
                    ([id, count]) => `
                      <div class="provider-analytics-service">
                        <div>
                          <span>
                            ${escapeHtml(
                              serviceName(
                                id,
                                serviceNames,
                              ),
                            )}
                          </span>
                          <strong>${count}</strong>
                        </div>

                        <div class="provider-analytics-track">
                          <div
                            style="width:${
                              count /
                              maxServiceCount *
                              100
                            }%"
                          ></div>
                        </div>
                      </div>
                    `,
                  )
                  .join('')
          }
        </div>

        <div class="provider-analytics-panel">
          <h3>Booking Demand</h3>

          <p>
            ${
              trendSelect.value === 'week'
                ? 'Last 12 weeks'
                : 'Last 12 months'
            } · requests created
          </p>

          <div
            class="provider-analytics-trend"
            role="img"
            aria-label="Booking requests by ${
              trendSelect.value
            }"
          >
            ${periods
              .map((item) => {
                const count =
                  periodCounts.get(item.key) || 0;

                const height = count
                  ? Math.max(
                      8,
                      count /
                        maxPeriodCount *
                        100,
                    )
                  : 0;

                return `
                  <div
                    class="provider-analytics-column"
                    title="${escapeHtml(
                      item.label,
                    )}: ${count} requests"
                  >
                    <span class="provider-analytics-value">
                      ${count}
                    </span>

                    <div class="provider-analytics-column-space">
                      <div
                        style="height:${height}%"
                      ></div>
                    </div>

                    <small>
                      ${escapeHtml(item.label)}
                    </small>
                  </div>
                `;
              })
              .join('')}
          </div>
        </div>
      </div>

      <div class="provider-analytics-panel provider-analytics-technicians">
        <h3>
          Most Completed Jobs by Service
        </h3>

        <p>
          Highest completed-job count per service,
          across all branches. This measures workload,
          not service quality.
        </p>

        ${
          technicianRows.length === 0
            ? `
              <p class="provider-analytics-empty">
                No completed jobs assigned
                to technicians yet.
              </p>
            `
            : `
              <div class="provider-analytics-table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Service</th>
                      <th>Technician(s)</th>
                      <th>Completed jobs</th>
                    </tr>
                  </thead>

                  <tbody>
                    ${technicianRows
                      .map(
                        (row) => `
                          <tr>
                            <td>
                              ${escapeHtml(row.name)}
                            </td>

                            <td>
                              ${escapeHtml(
                                row.leaders.join(', '),
                              )}
                            </td>

                            <td>
                              ${row.completed}
                            </td>
                          </tr>
                        `,
                      )
                      .join('')}
                  </tbody>
                </table>
              </div>
            `
        }
      </div>

      ${
        datedCount !== bookings.length
          ? `
            <p class="provider-analytics-footnote">
              ${bookings.length - datedCount}
              booking(s) have no usable creation or
              appointment date and are omitted from
              time-based charts.
            </p>
          `
          : ''
      }

      <p class="provider-analytics-footnote">
        Demand counts submitted requests, including
        requests later rejected or cancelled.
        Multi-service bookings count once for each
        selected service. Dates use booking creation
        time when available, otherwise appointment time.
      </p>
    `;
  }

  monthSelect.addEventListener(
    'change',
    render,
  );

  trendSelect.addEventListener(
    'change',
    render,
  );

  // Export the currently displayed analytics.
  downloadButton.addEventListener(
    'click',
    () => {
      if (
        !currentAnalytics ||
        downloadButton.disabled
      ) {
        return;
      }

      downloadButton.disabled = true;
      downloadButton.textContent =
        'Generating PDF...';

      exportMessage.textContent = '';

      try {
        const providerHeading =
          document.querySelector(
            '.provider-dashboard-heading h1',
          )?.textContent?.trim() || '';

        const providerName =
          providerHeading.replace(
            /^Welcome,\s*/i,
            '',
          );

        downloadProviderAnalyticsPdf(
          currentAnalytics,
          providerName,
        );

        exportMessage.textContent =
          'PDF report generated. Check your browser downloads.';
      } catch (error) {
        console.error(
          'Unable to export provider analytics PDF:',
          error,
        );

        exportMessage.textContent =
          'Unable to generate the PDF report. Please try again.';
      } finally {
        downloadButton.disabled = false;
        downloadButton.textContent =
          'Download Report (PDF)';
      }
    },
  );

  render();
}

export {
  setupProviderAnalytics,
};
