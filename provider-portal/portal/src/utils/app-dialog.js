
function openAppDialog({
  title,
  message,
  confirmLabel = 'OK',
  showCancel = false,
  destructive = false,
}) {
  return new Promise((resolve) => {
    const dialog = document.createElement('dialog');

    dialog.className = 'app-dialog';

    if (destructive) {
      dialog.classList.add('app-dialog-danger');
    }

    dialog.setAttribute('aria-label', title);

    dialog.innerHTML = `
      <div class="app-dialog-content">
        <div
          class="app-dialog-icon"
          aria-hidden="true"
        >
          !
        </div>

        <h2 class="app-dialog-title"></h2>

        <p class="app-dialog-message"></p>

        <div class="app-dialog-actions">
          <button
            type="button"
            class="app-dialog-cancel"
          >
            Cancel
          </button>

          <button
            type="button"
            class="app-dialog-confirm"
          >
            OK
          </button>
        </div>
      </div>
    `;

    dialog.querySelector(
      '.app-dialog-title',
    ).textContent = title;

    dialog.querySelector(
      '.app-dialog-message',
    ).textContent = message;

    const cancelButton = dialog.querySelector(
      '.app-dialog-cancel',
    );

    const confirmButton = dialog.querySelector(
      '.app-dialog-confirm',
    );

    confirmButton.textContent = confirmLabel;

    if (!showCancel) {
      cancelButton.remove();
    }

    confirmButton.addEventListener('click', () => {
      dialog.close('confirmed');
    });

    cancelButton.addEventListener('click', () => {
      dialog.close('cancelled');
    });

    dialog.addEventListener(
      'close',
      () => {
        const confirmed =
          dialog.returnValue === 'confirmed';

        dialog.remove();
        resolve(confirmed);
      },
      { once: true },
    );

    document.body.appendChild(dialog);
    dialog.showModal();

    if (showCancel) {
      cancelButton.focus();
    } else {
      confirmButton.focus();
    }
  });
}

async function showAppMessage(
  title,
  message,
) {
  await openAppDialog({
    title,
    message,
    confirmLabel: 'OK',
  });
}

function confirmAppAction({
  title,
  message,
  confirmLabel = 'Confirm',
  destructive = false,
}) {
  return openAppDialog({
    title,
    message,
    confirmLabel,
    showCancel: true,
    destructive,
  });
}

export {
  showAppMessage,
  confirmAppAction,
};
