
import {
  showAdminDashboardPage,
} from '../pages/admin/admin-dashboard-page.js';

import {
  showProviderDashboardPage,
} from '../pages/provider/provider-dashboard-page.js';

import {
  showProviderPendingPage,
} from '../pages/provider/provider-pending-page.js';

import {
  showProviderRegistrationPage,
} from '../pages/provider/provider-registration-page.js';

import {
  showAppMessage,
} from '../utils/app-dialog.js';

function routeUserByRole(
  app,
  userProfile,
  {
    onSignOut,
    onProviderApplications,
    onAdminReports,
    onProviderManagement,
  },
) {
  const role = userProfile.role;

  // =========================
  // ADMIN
  // =========================
  if (role === 'admin') {
    console.log('Route to Admin Dashboard.');

    showAdminDashboardPage(
      app,
      {
        adminName: userProfile.displayName,
        onSignOut,
        onProviderApplications,
        onAdminReports,
        onProviderManagement,
      },
    );
    return;
  }

  // =========================
  // PROVIDER
  // =========================
  if (role === 'provider') {
    const applicationStatus =
      userProfile.providerApplicationStatus || 'draft';

    if (
      userProfile.providerVerified === true ||
      applicationStatus === 'approved'
    ) {
      console.log('Route to Provider Dashboard.');

      showProviderDashboardPage(
        app,
        {
          providerId: userProfile.id,
          providerName: userProfile.displayName,
          onSignOut,
        },
      );
      return;
    }

    if (applicationStatus === 'pending') {
      showProviderPendingPage(
        app,
        {
          providerName: userProfile.displayName,
          onSignOut,
        },
      );
      return;
    }

    if (applicationStatus === 'rejected') {
      showAppMessage(
        'Provider Application Rejected',
        'Your provider application has been rejected. '
          + 'Resubmission is not currently available.',
      );
      return;
    }

    showProviderRegistrationPage(
      app,
      {
        providerProfile: userProfile,
        onSignOut,
      },
    );
    return;
  }

  // =========================
  // MOBILE-ONLY ROLES
  // =========================
  if (role === 'customer' || role === 'technician') {
    showAppMessage(
      'Mobile Application Required',
      'This account uses the HomeAssist mobile application. '
        + 'Please sign in through the mobile app instead.',
    );
    return;
  }

  // =========================
  // UNKNOWN ROLE
  // =========================
  showAppMessage(
    'Unable to Identify Account',
    'Unable to determine the account role. '
      + 'Please try signing in again.',
  );
}

export {
  routeUserByRole,
};
