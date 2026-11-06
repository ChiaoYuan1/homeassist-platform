import {
  requestPasswordReset,
} from '../../services/auth-service.js';


function showForgotPasswordPage(
  app,
  {
    onBackToLogin,
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
            ACCOUNT RECOVERY
          </p>

          <h1>
            Forgot your password?
          </h1>

          <p class="subtitle">
            Enter the email address registered
            with your HomeAssist account.
            A password reset link will be sent
            to that email address.
          </p>


          <form id="reset-form">

            <div class="form-group">

              <label for="reset-email">
                Email Address
              </label>

              <input
                id="reset-email"
                type="email"
                placeholder="example@email.com"
                autocomplete="email"
                required
              />

            </div>


            <button
              class="primary-button"
              type="submit"
              id="reset-button"
            >
              Send Reset Link
            </button>


            <p
              class="form-message"
              id="reset-message"
            ></p>

          </form>


          <div class="provider-register">

            <span>
              Remember your password?
            </span>

            <button
              type="button"
              class="text-button"
              id="back-to-login"
            >
              Back to Sign In
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
            Recover your account
            securely.
          </h2>

          <p>
            HomeAssist will send a secure
            password reset link to the email
            address registered with the
            account.
          </p>

        </div>

      </section>

    </main>
  `;


  const resetForm =
    document.querySelector(
      '#reset-form',
    );

  const resetEmail =
    document.querySelector(
      '#reset-email',
    );

  const resetMessage =
    document.querySelector(
      '#reset-message',
    );

  const resetButton =
    document.querySelector(
      '#reset-button',
    );

  const backToLoginButton =
    document.querySelector(
      '#back-to-login',
    );


  resetForm.addEventListener(
    'submit',
    async (event) => {
      event.preventDefault();

      resetMessage.textContent = '';

      resetMessage.classList.remove(
        'error',
      );

      resetButton.disabled = true;

      resetButton.textContent =
        'Sending...';


      try {
        await requestPasswordReset(
          resetEmail.value,
        );

        resetMessage.textContent =
          'If the email belongs to a HomeAssist account, a password reset link will be sent.';
      } catch (error) {
        console.error(
          'Password reset error:',
          error,
        );

        resetMessage.textContent =
          'Unable to process the password reset request. Please try again.';

        resetMessage.classList.add(
          'error',
        );
      } finally {
        resetButton.disabled = false;

        resetButton.textContent =
          'Send Reset Link';
      }
    },
  );


  backToLoginButton.addEventListener(
    'click',
    () => {
      onBackToLogin();
    },
  );
}


export {
  showForgotPasswordPage,
};