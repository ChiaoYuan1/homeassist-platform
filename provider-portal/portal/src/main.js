
import './style.css';
import './styles/admin.css';
import './styles/app-dialog.css';

import {
  showAppMessage,
} from './utils/app-dialog.js';

import {
  onAuthStateChanged,
} from 'firebase/auth';

import {
  auth,
} from './firebase.js';

import {
  showLoginPage,
} from './pages/auth/login-page.js';

import {
  showForgotPasswordPage,
} from './pages/auth/forgot-password-page.js';

import {
  getUserById,
} from './services/user-service.js';

import {
  routeUserByRole,
} from './router/role-router.js';

import {
  showProviderApplicationsPage,
} from './pages/admin/provider-applications-page.js';

import {
  showAdminReportsPage,
} from './pages/admin/admin-reports-page.js';

import {
  showAdminProviderManagementPage,
} from './pages/admin/admin-provider-management-page.js';

import {
  logOut,
  sendProviderVerificationEmail,
  checkProviderEmailVerified,
} from './services/auth-service.js';

import {
  showProviderAccountStep,
  showProviderEmailVerificationPage,
} from './pages/provider/provider-registration-page.js';

const app = document.querySelector('#app');
let currentUserProfile = null;

function routeStorageKey(userId) {
  return `homeassist:lastRoute:${userId}`;
}

function saveCurrentRoute(route) {
  if (!currentUserProfile?.id) {
    return;
  }

  localStorage.setItem(
    routeStorageKey(currentUserProfile.id),
    route,
  );
}

function getSavedRoute() {
  if (!currentUserProfile?.id) {
    return null;
  }

  return localStorage.getItem(
    routeStorageKey(currentUserProfile.id),
  );
}

// =========================
// LOGIN
// =========================

function openLoginPage() {
  showLoginPage(
    app,
    {
      onForgotPassword: openForgotPasswordPage,
      onRegisterProvider: openProviderAccountStep,
      onLoginSuccess: handleLoginSuccess,
    },
  );
}

// =========================
// PROVIDER ACCOUNT SIGN-UP
// =========================

function openProviderAccountStep(
  existingUser = null,
) {
  showProviderAccountStep(
    app,
    {
      existingUser,

      onBackToLogin: async () => {
        if (auth.currentUser) {
          await handleSignOut();
        } else {
          openLoginPage();
        }
      },

      onAccountCreated: async () => {
        try {
          await sendProviderVerificationEmail();
        } catch (error) {
          // Account/profile may already exist.
          // Verification can be retried from
          // the next screen.
          console.warn(
            'Initial verification email could not be sent:',
            error,
          );
        }

        openProviderVerificationPage();
      },
    },
  );
}

// =========================
// PROVIDER EMAIL VERIFICATION
// =========================

function openProviderVerificationPage() {
  showProviderEmailVerificationPage(
    app,
    {
      email: auth.currentUser?.email,
      onSignOut: handleSignOut,

      onResendVerification:
        sendProviderVerificationEmail,

      onCheckVerification: async () => {
        const verified =
          await checkProviderEmailVerified();

        if (verified) {
          await handleLoginSuccess(
            auth.currentUser,
            {
              restoreSavedRoute: false,
            },
          );
        }

        return verified;
      },
    },
  );
}

function openForgotPasswordPage() {
  showForgotPasswordPage(
    app,
    {
      onBackToLogin: openLoginPage,
    },
  );
}

// =========================
// LOGIN SUCCESS
// =========================

async function handleLoginSuccess(
  user,
  {
    restoreSavedRoute = true,
  } = {},
) {
  try {
    const userProfile =
      await getUserById(user.uid);

    console.log(
      'Firestore user profile:',
      userProfile,
    );

    if (!userProfile) {
      // Recover a sign-up where Firebase Auth
      // succeeded but profile setup failed.
      if (user.email) {
        openProviderAccountStep(user);
      } else {
        showAppMessage(
          'Account Not Found',
          'HomeAssist user profile was not found.',
        );

        openLoginPage();
      }

      return;
    }

    currentUserProfile = userProfile;

    if (
      userProfile.role === 'provider' &&
      userProfile.emailVerificationRequired === true
    ) {
      await checkProviderEmailVerified();

      if (!auth.currentUser.emailVerified) {
        openProviderVerificationPage();
        return;
      }
    }

    openCurrentUserPage({
      restoreSavedRoute,
    });
  } catch (error) {
    console.error(
      'Role routing error:',
      error,
    );

    showAppMessage(
      'Unable to Load Account',
      'Unable to load the HomeAssist account information.',
    );

    openLoginPage();
  }
}

// =========================
// ROLE ROUTING
// =========================

function openCurrentUserPage({
  restoreSavedRoute = true,
} = {}) {
  if (!currentUserProfile) {
    openLoginPage();
    return;
  }

  routeUserByRole(
    app,
    currentUserProfile,
    {
      onSignOut: handleSignOut,

      onProviderApplications:
        openProviderApplicationsPage,

      onAdminReports:
        openAdminReportsPage,

      onProviderManagement:
        openAdminProviderManagementPage,
    },
  );

  if (!restoreSavedRoute) {
    return;
  }

  const savedRoute = getSavedRoute();

  if (
    currentUserProfile.role === 'provider' &&
    savedRoute === 'provider-bookings'
  ) {
    requestAnimationFrame(() => {
      const button = document.querySelector(
        '#provider-bookings-button',
      );

      if (button) {
        button.click();
      }
    });

    return;
  }

  if (
    currentUserProfile.role === 'provider' &&
    savedRoute === 'provider-team'
  ) {
    requestAnimationFrame(() => {
      const button = document.querySelector(
        '#provider-team-availability-button',
      );

      if (button) {
        button.click();
      }
    });

    return;
  }

  if (
    currentUserProfile.role === 'admin' &&
    savedRoute === 'admin-provider-applications'
  ) {
    openProviderApplicationsPage({
      saveRoute: false,
    });

    return;
  }

  if (
    currentUserProfile.role === 'admin' &&
    savedRoute === 'admin-reports'
  ) {
    openAdminReportsPage({
      saveRoute: false,
    });

    return;
  }

  if (
    currentUserProfile.role === 'admin' &&
    savedRoute === 'admin-provider-management'
  ) {
    openAdminProviderManagementPage({
      saveRoute: false,
    });
  }
}

// =========================
// ADMIN DASHBOARD
// =========================

function openAdminDashboard() {
  if (currentUserProfile?.role !== 'admin') {
    return;
  }

  saveCurrentRoute(
    'admin-dashboard',
  );

  openCurrentUserPage({
    restoreSavedRoute: false,
  });
}

function openProviderApplicationsPage({
  saveRoute = true,
} = {}) {
  if (currentUserProfile?.role !== 'admin') {
    return;
  }

  if (saveRoute) {
    saveCurrentRoute(
      'admin-provider-applications',
    );
  }

  showProviderApplicationsPage(
    app,
    {
      onDashboard: openAdminDashboard,
      onSignOut: handleSignOut,
    },
  );

  // Preserve existing sidebar navigation.
  enableApplicationSidebarLinks();
}

function enableApplicationSidebarLinks() {
  const navigation =
    app.querySelector('.admin-nav');

  if (!navigation) {
    return;
  }

  for (
    const button of navigation.querySelectorAll(
      'button',
    )
  ) {
    const name =
      button.textContent.trim();

    if (name === 'Provider Management') {
      button.disabled = false;

      button.addEventListener(
        'click',
        openAdminProviderManagementPage,
      );
    } else if (name === 'Reports') {
      button.disabled = false;

      button.addEventListener(
        'click',
        openAdminReportsPage,
      );
    }
  }
}

function openAdminReportsPage({
  saveRoute = true,
} = {}) {
  if (currentUserProfile?.role !== 'admin') {
    return;
  }

  if (saveRoute) {
    saveCurrentRoute(
      'admin-reports',
    );
  }

  showAdminReportsPage(
    app,
    {
      onDashboard: openAdminDashboard,

      onProviderApplications:
        openProviderApplicationsPage,

      onProviderManagement:
        openAdminProviderManagementPage,

      onSignOut: handleSignOut,
    },
  );
}

function openAdminProviderManagementPage({
  saveRoute = true,
} = {}) {
  if (currentUserProfile?.role !== 'admin') {
    return;
  }

  if (saveRoute) {
    saveCurrentRoute(
      'admin-provider-management',
    );
  }

  showAdminProviderManagementPage(
    app,
    {
      onDashboard: openAdminDashboard,

      onProviderApplications:
        openProviderApplicationsPage,

      onAdminReports:
        openAdminReportsPage,

      onSignOut: handleSignOut,
    },
  );
}

// =========================
// SIGN OUT
// =========================

async function handleSignOut() {
  try {
    await logOut();

    currentUserProfile = null;

    console.log(
      'User signed out.',
    );

    openLoginPage();
  } catch (error) {
    console.error(
      'Sign out error:',
      error,
    );

    showAppMessage(
      'Sign Out Failed',
      'Unable to sign out. Please try again.',
    );
  }
}

// =========================
// PORTAL STARTUP
// =========================

function startPortal() {
  app.innerHTML = `
    <main
      style="
        min-height: 100vh;
        display: grid;
        place-items: center;
      "
    >
      <p>Loading HomeAssist...</p>
    </main>
  `;

  let unsubscribe = null;

  unsubscribe = onAuthStateChanged(
    auth,
    async (user) => {
      if (unsubscribe) {
        unsubscribe();
      }

      if (user) {
        await handleLoginSuccess(
          user,
          {
            restoreSavedRoute: true,
          },
        );

        return;
      }

      openLoginPage();
    },
  );
}

// Start HomeAssist Web Portal
startPortal();
