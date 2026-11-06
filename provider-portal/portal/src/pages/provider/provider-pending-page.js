function showProviderPendingPage(
  app,
  {
    providerName,
    onSignOut,
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
            PROVIDER APPLICATION
          </p>

          <h1>
            Application under review
          </h1>

          <p class="subtitle">
            ${
              providerName
                ? `Hello ${providerName}. `
                : ''
            }
            Your HomeAssist service provider
            account is currently awaiting
            administrator approval.
          </p>

          <button
            type="button"
            class="primary-button"
            id="sign-out-button"
            style="margin-top: 28px;"
          >
            Sign Out
          </button>

          <div
            style="
              margin-top: 28px;
              padding: 20px;
              border: 1px solid #E5E7EB;
              border-radius: 14px;
              background: #FFFFFF;
            "
          >

            <strong>
              What happens next?
            </strong>

            <p
              style="
                margin-top: 10px;
                margin-bottom: 0;
                color: #6B7280;
                line-height: 1.6;
              "
            >
              The submitted provider
              information will be reviewed
              by the HomeAssist administrator.
              Portal access will become
              available after approval.
            </p>

          </div>


          <button
            type="button"
            class="primary-button"
            id="back-to-login"
            style="margin-top: 28px;"
          >
            Back to Sign In
          </button>

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
            Provider verification
            helps keep HomeAssist
            reliable.
          </h2>

          <p>
            Provider information is reviewed
            before access to service management
            features is granted.
          </p>

        </div>

      </section>

    </main>
  `;

  const signOutButton =
    document.querySelector(
      '#sign-out-button',
    );

  signOutButton.addEventListener(
    'click',
    async () => {
      await onSignOut();
    },
  );
  
  const backToLoginButton =
    document.querySelector(
      '#back-to-login',
    );


  backToLoginButton.addEventListener(
    'click',
    () => {
      onSignOut();
    },
  );
}


export {
  showProviderPendingPage,
};