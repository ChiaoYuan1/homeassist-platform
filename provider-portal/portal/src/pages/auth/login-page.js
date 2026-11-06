
import {
  signIn,
} from '../../services/auth-service.js';

function showLoginPage(
  app,
  {
    onForgotPassword,
    onRegisterProvider,
    onLoginSuccess,
  },
) {
  app.innerHTML = `
    <main class="login-page">
      <section class="login-panel">
        <div class="brand">
          <div class="brand-icon">
            H
          </div>
          <span class="brand-name">
            HomeAssist
          </span>
        </div>

        <div class="login-content">
          <p class="portal-label">
            WEB PORTAL
          </p>
          <h1>
            Welcome back
          </h1>
          <p class="subtitle">
            Sign in to access the HomeAssist
            provider or administration portal.
          </p>

          <form id="login-form">
            <div class="form-group">
              <label for="email">
                Email Address
              </label>
              <input
                id="email"
                type="email"
                placeholder="example@email.com"
                autocomplete="email"
                required
              />
            </div>

            <div
              class="form-group"
              style="position: relative;"
            >
              <label for="password">
                Password
              </label>

              <input
                id="password"
                type="password"
                placeholder="Enter your password"
                autocomplete="current-password"
                style="
                  width: 100%;
                  box-sizing: border-box;
                  padding-right: 55px;
                "
                required
              />

              <button
                type="button"
                id="toggle-password-button"
                aria-label="Show password"
                aria-pressed="false"
                title="Show password"
                style="
                  position: absolute;
                  right: 10px;
                  bottom: 6px;
                  width: 38px;
                  height: 38px;
                  padding: 0;
                  border: none;
                  border-radius: 8px;
                  background: transparent;
                  color: #6b7280;
                  cursor: pointer;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  z-index: 1;
                "
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  aria-hidden="true"
                  style="display: block;"
                >
                  <path
                    d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"
                  />
                  <circle
                    cx="12"
                    cy="12"
                    r="3"
                  />
                  <path
                    id="password-visibility-slash"
                    d="M3 3l18 18"
                    style="display: block;"
                  />
                </svg>
              </button>
            </div>

            <div class="form-options">
              <label class="remember-option">
                <input
                  type="checkbox"
                  id="remember-me"
                />
                <span>
                  Remember me
                </span>
              </label>

              <button
                type="button"
                class="text-button"
                id="forgot-password-button"
              >
                Forgot password?
              </button>
            </div>

            <button
              class="primary-button"
              type="submit"
              id="sign-in-button"
            >
              Sign In
            </button>

            <p
              class="form-message"
              id="form-message"
            ></p>
          </form>

          <div class="provider-register">
            <span>
              Want to join HomeAssist as a
              service provider?
            </span>
            <button
              type="button"
              class="text-button register-button"
              id="register-provider-button"
            >
              Register as Provider
            </button>
          </div>
        </div>

        <p class="footer-text">
          HomeAssist Service Platform
        </p>
      </section>

      <section class="information-panel">
        <div class="information-content">
          <div class="info-icon">
            ✓
          </div>
          <h2>
            Manage home services
            with confidence.
          </h2>
          <p>
            HomeAssist connects customers,
            service providers and technicians
            through a secure and structured
            service management platform.
          </p>

          <div class="feature-list">
            <div class="feature-item">
              <span class="feature-check">
                ✓
              </span>
              <div>
                <strong>
                  Manage bookings
                </strong>
                <span>
                  Review and manage customer
                  service requests.
                </span>
              </div>
            </div>

            <div class="feature-item">
              <span class="feature-check">
                ✓
              </span>
              <div>
                <strong>
                  Coordinate technicians
                </strong>
                <span>
                  Organise team availability
                  and assignments.
                </span>
              </div>
            </div>

            <div class="feature-item">
              <span class="feature-check">
                ✓
              </span>
              <div>
                <strong>
                  Track service progress
                </strong>
                <span>
                  Keep job status and service
                  activity organised.
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>
  `;

  const form = document.querySelector('#login-form');
  const emailInput = document.querySelector('#email');
  const passwordInput = document.querySelector('#password');

  const togglePasswordButton = document.querySelector(
    '#toggle-password-button',
  );

  const passwordVisibilitySlash = document.querySelector(
    '#password-visibility-slash',
  );

  const rememberMeInput = document.querySelector('#remember-me');
  const message = document.querySelector('#form-message');
  const signInButton = document.querySelector('#sign-in-button');

  const forgotPasswordButton = document.querySelector(
    '#forgot-password-button',
  );

  const registerProviderButton = document.querySelector(
    '#register-provider-button',
  );

  togglePasswordButton.addEventListener(
    'click',
    () => {
      const showPassword =
        passwordInput.type === 'password';

      passwordInput.type = showPassword
        ? 'text'
        : 'password';

      // Open eye: password visible.
      // Crossed-out eye: password hidden.
      passwordVisibilitySlash.style.display =
        showPassword ? 'none' : 'block';

      togglePasswordButton.setAttribute(
        'aria-label',
        showPassword ? 'Hide password' : 'Show password',
      );

      togglePasswordButton.setAttribute(
        'aria-pressed',
        String(showPassword),
      );

      togglePasswordButton.title = showPassword
        ? 'Hide password'
        : 'Show password';
    },
  );

  form.addEventListener(
    'submit',
    async (event) => {
      event.preventDefault();
      message.textContent = '';
      message.classList.remove('error');

      signInButton.disabled = true;
      signInButton.textContent = 'Signing In...';

      try {
        const user = await signIn(
          emailInput.value,
          passwordInput.value,
          rememberMeInput.checked,
        );

        console.log('Logged in user:', user);
        await onLoginSuccess(user);
      } catch (error) {
        console.error('Firebase login error:', error);

        message.textContent =
          'Unable to sign in. Please check your email and password.';

        message.classList.add('error');
      } finally {
        signInButton.disabled = false;
        signInButton.textContent = 'Sign In';
      }
    },
  );

  forgotPasswordButton.addEventListener(
    'click',
    () => {
      onForgotPassword();
    },
  );

  registerProviderButton.addEventListener(
    'click',
    () => {
      if (onRegisterProvider) {
        onRegisterProvider();
      }
    },
  );
}

export {
  showLoginPage,
};
