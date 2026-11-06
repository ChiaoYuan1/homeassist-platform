import {
  showAppMessage,
} from '../../utils/app-dialog.js';

import {
  auth,
} from '../../firebase.js';

import {
  createProviderAccount,
  finishProviderAccountSetup,
} from '../../services/auth-service.js';

import {

  getRegistrationCatalogue,

} from '../../services/catalog-service.js';

import {

  saveBusinessInformation,

  saveServicesOffered,

  saveVerificationAndLocations,

  submitProviderApplication,

} from '../../services/provider-service.js';



const NOMINATIM_BASE_URL = 'https://nominatim.openstreetmap.org';

const NOMINATIM_MIN_INTERVAL_MS = 1100;

const geocodingCache = new Map();

let lastNominatimRequestAt = 0;





function showProviderRegistrationPage(

  app,

  {

    providerProfile,

    onSignOut,

  },

) {

  const currentStep =

    providerProfile.registrationStep ||

    'business';



  const providerName =

    providerProfile.displayName ||

    'Service Provider';



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





        <div class="login-content provider-registration-content">



          <p class="portal-label">

            PROVIDER REGISTRATION

          </p>



          <h1>

            Continue your registration

          </h1>



          <p class="subtitle">

            Welcome back,

            ${escapeHtml(providerName)}.

            Complete the provider application

            before submitting it for

            administrator review.

          </p>





          <div id="registration-step-content">

          </div>





          <button

            type="button"

            class="text-button"

            id="provider-sign-out-button"

          >

            Sign Out

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

            Complete your provider

            application.

          </h2>



          <p>

            Register business services,

            service locations and verification

            documents before administrator

            approval.

          </p>



        </div>



      </section>



    </main>

  `;



  const stepContent =

    document.querySelector(

      '#registration-step-content',

    );



  const signOutButton =

    document.querySelector(

      '#provider-sign-out-button',

    );





  if (currentStep === 'business') {

    showBusinessStep(

      stepContent,

      app,

      providerProfile,

      onSignOut,

    );

  } else if (currentStep === 'services') {

    showServicesStep(

      stepContent,

      app,

      providerProfile,

      onSignOut,

    );

  } else if (currentStep === 'documents') {

    showVerificationStep(

      stepContent,

      app,

      providerProfile,

      onSignOut,

    );

  } else {

    showReviewStep(

      stepContent,

      app,

      providerProfile,

      onSignOut,

    );

  }





  signOutButton.addEventListener(

    'click',

    async () => {

      await onSignOut();

    },

  );

}





function showBusinessStep(

  container,

  app,

  providerProfile,

  onSignOut,

) {

  container.innerHTML = `

    <div class="registration-current-card">



      <p class="portal-label">

        STEP 1 OF 4

      </p>



      <h2>

        Business Information

      </h2>



      <p>

        Enter the service provider's

        registered business information.

      </p>





      <form id="business-information-form">



        <div class="form-group">



          <label for="business-name">

            Business Name

          </label>



          <input

            id="business-name"

            type="text"

            value="${escapeAttribute(

              providerProfile.businessName || '',

            )}"

            placeholder="Enter business name"

            required

          />



        </div>





        <div class="form-group">



          <label for="registration-number">

            Business Registration Number

          </label>



          <input

            id="registration-number"

            type="text"

            value="${escapeAttribute(

              providerProfile.businessRegistrationNumber || '',

            )}"

            placeholder="Enter registration number"

            required

          />



        </div>





        <div class="form-group">



          <label for="business-address">

            Business Address

          </label>



          <input

            id="business-address"

            type="text"

            value="${escapeAttribute(

              providerProfile.businessAddress || '',

            )}"

            placeholder="Enter business address"

            required

          />



        </div>





        <button

          type="submit"

          class="primary-button"

          id="business-continue-button"

        >

          Save & Continue

        </button>





        <p

          class="form-message"

          id="business-message"

        ></p>



      </form>



    </div>

  `;



  const form =

    document.querySelector(

      '#business-information-form',

    );



  const businessName =

    document.querySelector(

      '#business-name',

    );



  const registrationNumber =

    document.querySelector(

      '#registration-number',

    );



  const businessAddress =

    document.querySelector(

      '#business-address',

    );



  const continueButton =

    document.querySelector(

      '#business-continue-button',

    );



  const message =

    document.querySelector(

      '#business-message',

    );





  form.addEventListener(

    'submit',

    async (event) => {

      event.preventDefault();



      clearMessage(message);



      continueButton.disabled = true;

      continueButton.textContent = 'Saving...';



      try {

        await saveBusinessInformation(

          providerProfile.id,

          {

            businessName:

              businessName.value,



            businessRegistrationNumber:

              registrationNumber.value,



            businessAddress:

              businessAddress.value,

          },

        );



        const updatedProfile = {

          ...providerProfile,



          businessName:

            businessName.value.trim(),



          businessRegistrationNumber:

            registrationNumber.value.trim(),



          businessAddress:

            businessAddress.value.trim(),



          registrationStep:

            'services',

        };



        showProviderRegistrationPage(

          app,

          {

            providerProfile:

              updatedProfile,



            onSignOut,

          },

        );

      } catch (error) {

        console.error(

          'Unable to save business information:',

          error,

        );



        showError(

          message,

          'Unable to save the business information. Please try again.',

        );



        continueButton.disabled = false;

        continueButton.textContent = 'Save & Continue';

      }

    },

  );

}





async function showServicesStep(

  container,

  app,

  providerProfile,

  onSignOut,

) {

  container.innerHTML = `

    <div class="registration-current-card">



      <p class="portal-label">

        STEP 2 OF 4

      </p>



      <h2>

        Services Offered

      </h2>



      <p>

        Loading the HomeAssist service catalogue...

      </p>



    </div>

  `;



  try {

    const catalogue =

      await getRegistrationCatalogue();



    const existingCategoryIds =

      normaliseExistingCategoryIds(

        providerProfile,

      );



    const existingServiceIds =

      Array.isArray(providerProfile.serviceIds)

        ? providerProfile.serviceIds

        : [];



    container.innerHTML = `

      <div class="registration-current-card">



        <p class="portal-label">

          STEP 2 OF 4

        </p>



        <h2>

          Services Offered

        </h2>



        <p>

          Select each service category the business

          provides, then choose the specific services

          available to customers.

        </p>





        <form id="services-form">



          <div class="provider-category-options">



            ${catalogue.map((category) =>

              buildCategoryCard(

                category,

                existingCategoryIds,

                existingServiceIds,

              ),

            ).join('')}



          </div>





          <div class="registration-navigation-row">

            <button

              type="button"

              class="secondary-button registration-back-button"

              id="services-back-button"

            >

              Back

            </button>



            <button

              type="submit"

              class="primary-button"

              id="services-continue-button"

            >

              Save & Continue

            </button>

          </div>





          <p

            class="form-message"

            id="services-message"

          ></p>



        </form>



      </div>

    `;



    wireCategorySelection();



    const form =

      document.querySelector(

        '#services-form',

      );



    const backButton =

      document.querySelector(

        '#services-back-button',

      );



    const continueButton =

      document.querySelector(

        '#services-continue-button',

      );



    const message =

      document.querySelector(

        '#services-message',

      );





    backButton.addEventListener(

      'click',

      () => {

        navigateRegistrationStep(

          app,

          providerProfile,

          onSignOut,

          'business',

        );

      },

    );



    form.addEventListener(

      'submit',

      async (event) => {

        event.preventDefault();



        clearMessage(message);



        const categoryIds = Array.from(

          document.querySelectorAll(

            'input[name="provider-category"]:checked',

          ),

        ).map((input) => input.value);



        const serviceIds = Array.from(

          document.querySelectorAll(

            'input[name="provider-service"]:checked',

          ),

        ).map((input) => input.value);



        if (categoryIds.length === 0) {

          showError(

            message,

            'Please select at least one service category.',

          );

          return;

        }



        const categoryWithoutService =

          categoryIds.find((categoryId) => {

            const category = catalogue.find(

              (item) => item.id === categoryId,

            );



            if (!category) {

              return true;

            }



            return !category.services.some(

              (service) =>

                serviceIds.includes(service.id),

            );

          });



        if (categoryWithoutService) {

          const category = catalogue.find(

            (item) =>

              item.id === categoryWithoutService,

          );



          showError(

            message,

            `Please select at least one service under ${category?.name || 'each selected category'}.`,

          );

          return;

        }



        continueButton.disabled = true;

        continueButton.textContent = 'Saving...';



        try {

          await saveServicesOffered(

            providerProfile.id,

            {

              categoryIds,

              serviceIds,

            },

          );



          const updatedProfile = {

            ...providerProfile,

            categoryIds,

            serviceIds,

            servicesOffered:

              categoryIds,

            registrationStep:

              'documents',

          };



          showProviderRegistrationPage(

            app,

            {

              providerProfile:

                updatedProfile,



              onSignOut,

            },

          );

        } catch (error) {

          console.error(

            'Unable to save provider services:',

            error,

          );



          showError(

            message,

            'Unable to save the selected services. Please try again.',

          );



          continueButton.disabled = false;

          continueButton.textContent = 'Save & Continue';

        }

      },

    );

  } catch (error) {

    console.error(

      'Unable to load service catalogue:',

      error,

    );



    container.innerHTML = `

      <div class="registration-current-card">



        <p class="portal-label">

          STEP 2 OF 4

        </p>



        <h2>

          Services Offered

        </h2>



        <p class="form-message error">

          Unable to load the HomeAssist service catalogue.

          Please make sure the Firestore service catalogue has been created.

        </p>



      </div>

    `;

  }

}





function showVerificationStep(

  container,

  app,

  providerProfile,

  onSignOut,

) {

  const selectedCategoryIds =

    normaliseExistingCategoryIds(

      providerProfile,

    );



  const existingBranches =

    Array.isArray(providerProfile.registrationBranches) &&

    providerProfile.registrationBranches.length > 0

      ? providerProfile.registrationBranches

      : [

          {

            name: 'Main Branch',

            address:

              providerProfile.businessAddress || '',

            latitude: '',

            longitude: '',

          },

        ];



  container.innerHTML = `

    <div class="registration-current-card step3-registration-card">



      <div class="step3-title-row">

        <div>

          <p class="portal-label step3-step-label">

            STEP 3 OF 4

          </p>



          <h2>

            Locations & Verification

          </h2>



          <p class="step3-intro">

            Add the locations your team operates from and provide the

            documents needed for HomeAssist verification.

          </p>

        </div>



        <div class="step3-progress-badge" aria-label="Step 3 of 4">

          <span>3</span>

          <small>/ 4</small>

        </div>

      </div>



      <div class="step3-progress-track" aria-hidden="true">

        <span></span>

      </div>



      <form id="verification-form">



        <section class="step3-section-card">

          <div class="step3-section-header">

            <div class="step3-section-icon" aria-hidden="true">

              <span>01</span>

            </div>



            <div class="step3-section-heading-copy">

              <div class="step3-section-title-row">

                <h3>Service Locations</h3>

                <span class="step3-soft-badge">

                  Multiple branches supported

                </span>

              </div>



              <p>

                Add every branch that can receive HomeAssist jobs.

                Customers will be matched to the nearest suitable active branch.

              </p>

            </div>

          </div>



          <div class="step3-info-note">

            <strong>Location matching</strong>

            <span>

              The latitude and longitude are used by the mobile app to

              calculate provider distance using the branch location.

            </span>

          </div>



          <div id="branch-list">

            ${existingBranches.map(

              (branch, index) =>

                buildBranchEditor(

                  branch,

                  index,

                ),

            ).join('')}

          </div>



          <div class="step3-add-branch-row">

            <button

              type="button"

              class="secondary-button add-branch-button"

              id="add-branch-button"

            >

              <span class="button-plus" aria-hidden="true">+</span>

              Add Another Branch

            </button>



            <span class="step3-add-branch-hint">

              Add another location only if the business operates from more than one branch.

            </span>

          </div>

        </section>



        <section class="step3-section-card verification-section-card">

          <div class="step3-section-header">

            <div class="step3-section-icon" aria-hidden="true">

              <span>02</span>

            </div>



            <div class="step3-section-heading-copy">

              <div class="step3-section-title-row">

                <h3>Verification Documents</h3>

                <span class="step3-soft-badge">

                  PDF / JPG / PNG

                </span>

              </div>



              <p>

                Required documents are based on the service categories

                selected in Step 2. Each file must be 10 MB or smaller.

              </p>

            </div>

          </div>



          <div class="verification-list">

            ${buildDocumentInput({

              id: 'ssm-document',

              label: 'SSM Business Registration',

              required: !providerProfile.verificationDocuments?.ssm,

              existingDocument:

                providerProfile.verificationDocuments?.ssm,

            })}



            ${selectedCategoryIds.includes('electrical')

              ? `

                ${buildDocumentInput({

                  id: 'st-contractor-document',

                  label: 'ST Electrical Contractor Registration',

                  required:

                    !providerProfile.verificationDocuments?.stContractor,

                  existingDocument:

                    providerProfile.verificationDocuments?.stContractor,

                })}



                ${buildDocumentInput({

                  id: 'st-competency-document',

                  label: 'ST Competency Certificate',

                  required:

                    !providerProfile.verificationDocuments?.stCompetency,

                  existingDocument:

                    providerProfile.verificationDocuments?.stCompetency,

                })}

              `

              : ''}



            ${selectedCategoryIds.includes('gas_replacement')

              ? buildDocumentInput({

                  id: 'kpdn-document',

                  label: 'KPDN LPG / Controlled Goods Licence',

                  required:

                    !providerProfile.verificationDocuments?.kpdn,

                  existingDocument:

                    providerProfile.verificationDocuments?.kpdn,

                })

              : ''}

          </div>



          <div class="step3-security-note">

            <span class="step3-security-dot" aria-hidden="true"></span>

            <p>

              Uploaded documents are used for administrator verification

              before the provider can appear to customers.

            </p>

          </div>

        </section>



        <div class="step3-footer-action">

          <div>

            <strong>Next: Review & Submit</strong>

            <span>

              Check all business, service, location and document details before submission.

            </span>

          </div>



          <div class="step3-footer-buttons">

            <button

              type="button"

              class="secondary-button registration-back-button"

              id="verification-back-button"

            >

              Back

            </button>



            <button

              type="submit"

              class="primary-button step3-continue-button"

              id="verification-continue-button"

            >

              Save & Continue

            </button>

          </div>

        </div>



        <p

          class="form-message"

          id="verification-message"

        ></p>



      </form>



    </div>

  `;



  const branchList =

    document.querySelector(

      '#branch-list',

    );



  const addBranchButton =

    document.querySelector(

      '#add-branch-button',

    );



  const form =

    document.querySelector(

      '#verification-form',

    );



  const backButton =

    document.querySelector(

      '#verification-back-button',

    );



  const continueButton =

    document.querySelector(

      '#verification-continue-button',

    );



  const message =

    document.querySelector(

      '#verification-message',

    );



  wireBranchControls(branchList);



  backButton.addEventListener(

    'click',

    () => {

      navigateRegistrationStep(

        app,

        providerProfile,

        onSignOut,

        'services',

      );

    },

  );



  form

    .querySelectorAll('.verification-file-input')

    .forEach((input) => {

      input.addEventListener(

        'change',

        () => {

          const card =

            input.closest(

              '.verification-upload-card',

            );



          const fileName =

            card?.querySelector(

              '.verification-file-name',

            );



          if (!fileName) {

            return;

          }



          if (input.files?.[0]) {

            fileName.textContent =

              input.files[0].name;



            card?.classList.add(

              'has-selected-file',

            );

          } else {

            fileName.textContent =

              'No new file selected';



            card?.classList.remove(

              'has-selected-file',

            );

          }

        },

      );

    });



  addBranchButton.addEventListener(

    'click',

    () => {

      const index =

        branchList.querySelectorAll(

          '.provider-branch-editor',

        ).length;



      branchList.insertAdjacentHTML(

        'beforeend',

        buildBranchEditor(

          {

            name: `Branch ${index + 1}`,

            address: '',

            latitude: '',

            longitude: '',

          },

          index,

        ),

      );



      wireBranchControls(branchList);



      branchList

        .lastElementChild

        ?.scrollIntoView({

          behavior: 'smooth',

          block: 'center',

        });

    },

  );



  form.addEventListener(

    'submit',

    async (event) => {

      event.preventDefault();



      clearMessage(message);



      continueButton.disabled = true;

      continueButton.textContent = 'Checking Locations...';



      try {

        await resolveBranchLocationsFromForm(

          branchList,

        );

      } catch (error) {

        console.error(

          'Unable to resolve branch location:',

          error,

        );



        showError(

          message,

          error.message ||

            'Unable to locate one of the branch addresses. Please check the address and try again.',

        );



        continueButton.disabled = false;

        continueButton.textContent = 'Save & Continue';

        return;

      }



      const branches =

        readBranchesFromForm();



      if (branches.length === 0) {

        continueButton.disabled = false;

        continueButton.textContent = 'Save & Continue';

        showError(

          message,

          'Please add at least one service location.',

        );

        return;

      }



      if (

        branches.some(

          (branch) =>

            !branch.name ||

            !branch.address ||

            !Number.isFinite(branch.latitude) ||

            !Number.isFinite(branch.longitude),

        )

      ) {

        showError(

          message,

          'Please complete the branch name and address for every location.',

        );

        continueButton.disabled = false;

        continueButton.textContent = 'Save & Continue';

        return;

      }



      const files = {

        ssm:

          getSelectedFile('ssm-document'),



        stContractor:

          getSelectedFile('st-contractor-document'),



        stCompetency:

          getSelectedFile('st-competency-document'),



        kpdn:

          getSelectedFile('kpdn-document'),

      };



      const requiredDocumentKeys = [

        'ssm',

      ];



      if (

        selectedCategoryIds.includes(

          'electrical',

        )

      ) {

        requiredDocumentKeys.push(

          'stContractor',

          'stCompetency',

        );

      }



      if (

        selectedCategoryIds.includes(

          'gas_replacement',

        )

      ) {

        requiredDocumentKeys.push(

          'kpdn',

        );

      }



      const missingDocument =

        requiredDocumentKeys.find(

          (key) =>

            !files[key] &&

            !providerProfile.verificationDocuments?.[key],

        );



      if (missingDocument) {

        showError(

          message,

          'Please upload all required verification documents.',

        );

        continueButton.disabled = false;

        continueButton.textContent = 'Save & Continue';

        return;

      }



      continueButton.textContent = 'Uploading...';



      try {

        const uploadedDocuments =

          await saveVerificationAndLocations(

            providerProfile.id,

            {

              branches,

              files,

              existingDocuments:

                providerProfile.verificationDocuments || {},

            },

          );



        const updatedProfile = {

          ...providerProfile,

          registrationBranches:

            branches,

          verificationDocuments:

            uploadedDocuments,

          registrationStep:

            'review',

        };



        showProviderRegistrationPage(

          app,

          {

            providerProfile:

              updatedProfile,

            onSignOut,

          },

        );

      } catch (error) {

        console.error(

          'Unable to save provider verification:',

          error,

        );



        showError(

          message,

          error.message ||

            'Unable to save the verification information. Please try again.',

        );



        continueButton.disabled = false;

        continueButton.textContent = 'Save & Continue';

      }

    },

  );

}



async function showReviewStep(

  container,

  app,

  providerProfile,

  onSignOut,

) {

  container.innerHTML = `

    <div class="registration-current-card">



      <p class="portal-label">

        STEP 4 OF 4

      </p>



      <h2>

        Review & Submit

      </h2>



      <p>

        Loading the application summary...

      </p>



    </div>

  `;



  try {

    const catalogue =

      await getRegistrationCatalogue();



    const selectedCategoryIds =

      normaliseExistingCategoryIds(

        providerProfile,

      );



    const selectedServiceIds =

      Array.isArray(providerProfile.serviceIds)

        ? providerProfile.serviceIds

        : [];



    const selectedCategoryNames =

      catalogue

        .filter((category) =>

          selectedCategoryIds.includes(

            category.id,

          ),

        )

        .map((category) => category.name);



    const selectedServiceNames =

      catalogue

        .flatMap((category) => category.services)

        .filter((service) =>

          selectedServiceIds.includes(

            service.id,

          ),

        )

        .map((service) => service.name);



    const serviceSelectionComplete =

      selectedCategoryIds.length > 0 &&

      selectedServiceIds.length > 0;



    const branches =

      providerProfile.registrationBranches || [];



    const documents =

      providerProfile.verificationDocuments || {};



    container.innerHTML = `

      <div class="registration-current-card">



        <p class="portal-label">

          STEP 4 OF 4

        </p>



        <h2>

          Review & Submit

        </h2>



        <p>

          Check the application before sending it

          to the HomeAssist administrator.

        </p>





        <div class="registration-review-grid">



          ${buildReviewSection(

            'Business',

            [

              providerProfile.businessName,

              providerProfile.businessRegistrationNumber,

              providerProfile.businessAddress,

            ],

          )}



          ${buildReviewSection(

            'Categories',

            selectedCategoryNames,

          )}



          ${buildReviewSection(

            'Services',

            selectedServiceNames,

          )}



          ${buildReviewSection(

            'Service Locations',

            branches.map(

              (branch) =>

                `${branch.name} — ${branch.address}`,

            ),

          )}



          ${buildReviewSection(

            'Verification Documents',

            Object.values(documents).map(

              (document) =>

                document.originalName,

            ),

          )}



        </div>





        ${!serviceSelectionComplete

          ? `

              <p class="form-message error registration-review-warning">

                Service categories and specific services are required before submission.

                Use Back to return to Step 2 and complete the service selection.

              </p>

            `

          : ''}



        <div class="registration-navigation-row registration-review-actions">

          <button

            type="button"

            class="secondary-button registration-back-button"

            id="review-back-button"

          >

            Back

          </button>



          <button

            type="button"

            class="primary-button"

            id="submit-application-button"

            ${serviceSelectionComplete ? '' : 'disabled'}

          >

            Submit for Administrator Review

          </button>

        </div>





        <p

          class="form-message"

          id="submit-application-message"

        ></p>



      </div>

    `;



    const backButton =

      document.querySelector(

        '#review-back-button',

      );



    const submitButton =

      document.querySelector(

        '#submit-application-button',

      );



    const message =

      document.querySelector(

        '#submit-application-message',

      );





    backButton.addEventListener(

      'click',

      () => {

        navigateRegistrationStep(

          app,

          providerProfile,

          onSignOut,

          'documents',

        );

      },

    );



    submitButton.addEventListener(

      'click',

      async () => {

        clearMessage(message);



        submitButton.disabled = true;

        submitButton.textContent = 'Submitting...';



        try {

          await submitProviderApplication(

            providerProfile.id,

          );



          const updatedProfile = {

            ...providerProfile,

            providerApplicationStatus:

              'pending',

          };



          showProviderRegistrationPage(

            app,

            {

              providerProfile:

                updatedProfile,

              onSignOut,

            },

          );



          window.location.reload();

        } catch (error) {

          console.error(

            'Unable to submit provider application:',

            error,

          );



          showError(

            message,

            'Unable to submit the provider application. Please try again.',

          );



          submitButton.disabled = false;

          submitButton.textContent =

            'Submit for Administrator Review';

        }

      },

    );

  } catch (error) {

    console.error(

      'Unable to load application review:',

      error,

    );



    container.innerHTML = `

      <div class="registration-current-card">



        <p class="portal-label">

          STEP 4 OF 4

        </p>



        <h2>

          Review & Submit

        </h2>



        <p class="form-message error">

          Unable to load the application summary.

        </p>



      </div>

    `;

  }

}





function navigateRegistrationStep(

  app,

  providerProfile,

  onSignOut,

  registrationStep,

) {

  showProviderRegistrationPage(

    app,

    {

      providerProfile: {

        ...providerProfile,

        registrationStep,

      },

      onSignOut,

    },

  );

}





function buildCategoryCard(

  category,

  existingCategoryIds,

  existingServiceIds,

) {

  const categorySelected =

    existingCategoryIds.includes(

      category.id,

    );



  return `

    <section

      class="provider-category-card ${categorySelected ? 'selected' : ''}"

      data-category-card="${escapeAttribute(category.id)}"

    >



      <label class="provider-category-heading">



        <input

          type="checkbox"

          name="provider-category"

          value="${escapeAttribute(category.id)}"

          ${categorySelected ? 'checked' : ''}

        />



        <div>

          <strong>

            ${escapeHtml(category.name || category.id)}

          </strong>



          <span>

            ${escapeHtml(category.description || '')}

          </span>

        </div>



      </label>





      <div

        class="provider-service-suboptions ${categorySelected ? '' : 'hidden'}"

        data-service-group="${escapeAttribute(category.id)}"

      >



        ${category.services.length > 0

          ? category.services.map((service) => `

              <label class="provider-service-checkbox">



                <input

                  type="checkbox"

                  name="provider-service"

                  value="${escapeAttribute(service.id)}"

                  data-category-id="${escapeAttribute(category.id)}"

                  ${existingServiceIds.includes(service.id) ? 'checked' : ''}

                  ${categorySelected ? '' : 'disabled'}

                />



                <span>

                  ${escapeHtml(service.name || service.id)}

                </span>



              </label>

            `).join('')

          : `

              <p class="provider-empty-note">

                No active services are available in this category.

              </p>

            `}



      </div>



    </section>

  `;

}





function wireCategorySelection() {

  const categoryInputs =

    document.querySelectorAll(

      'input[name="provider-category"]',

    );



  categoryInputs.forEach((input) => {

    input.addEventListener(

      'change',

      () => {

        const categoryId = input.value;



        const card =

          input.closest(

            '.provider-category-card',

          );



        const group =

          document.querySelector(

            `[data-service-group="${categoryId}"]`,

          );



        const serviceInputs =

          group?.querySelectorAll(

            'input[name="provider-service"]',

          ) || [];



        card?.classList.toggle(

          'selected',

          input.checked,

        );



        group?.classList.toggle(

          'hidden',

          !input.checked,

        );



        serviceInputs.forEach(

          (serviceInput) => {

            serviceInput.disabled =

              !input.checked;



            if (!input.checked) {

              serviceInput.checked = false;

            }

          },

        );

      },

    );

  });

}





function buildBranchEditor(

  branch,

  index,

) {

  const branchNumber =

    String(index + 1).padStart(2, '0');



  const latitude =

    branch.latitude ?? '';



  const longitude =

    branch.longitude ?? '';



  const hasCoordinates =

    latitude !== '' &&

    longitude !== '';



  return `

    <section

      class="provider-branch-editor"

      data-branch-index="${index}"

      data-resolved-address="${escapeAttribute(branch.address || '')}"

      data-location-dirty="${hasCoordinates ? 'false' : 'true'}"

    >



      <div class="provider-branch-header">

        <div class="provider-branch-heading">

          <span class="branch-index-badge">

            ${branchNumber}

          </span>



          <div>

            <strong>

              ${index === 0 ? 'Primary Service Location' : `Additional Branch ${index}`}

            </strong>

            <span>

              Used for nearby-provider matching and branch assignment.

            </span>

          </div>

        </div>



        <button

          type="button"

          class="text-button remove-branch-button"

        >

          Remove

        </button>

      </div>



      <div class="provider-branch-fields">

        <div class="form-group">

          <label>Branch Name</label>

          <input

            type="text"

            class="branch-name-input"

            value="${escapeAttribute(branch.name || '')}"

            placeholder="e.g. Bayan Lepas Branch"

            required

          />

        </div>



        <div class="form-group">

          <label>Branch Address</label>

          <textarea

            class="branch-address-input"

            rows="3"

            placeholder="Enter the full service address"

            required

          >${escapeHtml(branch.address || '')}</textarea>

        </div>

      </div>



      <input

        type="hidden"

        class="branch-latitude-input"

        value="${escapeAttribute(latitude)}"

      />



      <input

        type="hidden"

        class="branch-longitude-input"

        value="${escapeAttribute(longitude)}"

      />



      <div class="branch-location-tools">

        <button

          type="button"

          class="secondary-button use-browser-location-button"

        >

          Use Current Location

        </button>



        <div

          class="branch-location-status ${hasCoordinates ? 'success' : ''}"

          role="status"

          aria-live="polite"

        >

          <span class="branch-location-status-dot"></span>

          <span class="branch-location-status-text">

            ${hasCoordinates

              ? 'Location coordinates are ready. You can still edit the address.'

              : 'Use current location or enter the branch address manually.'}

          </span>

        </div>

      </div>



      <p class="provider-location-note">

        If the address is edited, HomeAssist will update the coordinates

        from the address when you save this step.

      </p>



      <p class="provider-location-attribution">

        Address lookup powered by OpenStreetMap Nominatim.

      </p>



    </section>

  `;

}





function wireBranchControls(branchList) {

  branchList

    .querySelectorAll(

      '.provider-branch-editor',

    )

    .forEach((editor) => {

      const addressInput =

        editor.querySelector(

          '.branch-address-input',

        );



      if (

        addressInput &&

        addressInput.dataset.wired !== 'true'

      ) {

        addressInput.dataset.wired = 'true';



        addressInput.addEventListener(

          'input',

          () => {

            const resolvedAddress =

              editor.dataset.resolvedAddress || '';



            const currentAddress =

              addressInput.value.trim();



            const changed =

              normaliseAddress(currentAddress) !==

              normaliseAddress(resolvedAddress);



            editor.dataset.locationDirty =

              changed ? 'true' : 'false';



            if (changed) {

              setBranchLocationStatus(

                editor,

                'Address changed. Location will be updated when you save.',

                'pending',

              );

            }

          },

        );

      }

    });



  branchList

    .querySelectorAll(

      '.use-browser-location-button',

    )

    .forEach((button) => {

      if (button.dataset.wired === 'true') {

        return;

      }



      button.dataset.wired = 'true';



      button.addEventListener(

        'click',

        () => {

          const editor =

            button.closest(

              '.provider-branch-editor',

            );



          useBrowserLocation(

            editor,

            button,

          );

        },

      );

    });



  branchList

    .querySelectorAll(

      '.remove-branch-button',

    )

    .forEach((button) => {

      if (button.dataset.wired === 'true') {

        return;

      }



      button.dataset.wired = 'true';



      button.addEventListener(

        'click',

        () => {

          const editors =

            branchList.querySelectorAll(

              '.provider-branch-editor',

            );

          if (editors.length <= 1) {

            showAppMessage(
              'Service Location Required',
              'At least one service location is required.',
            );

            return;

          }

          button

            .closest('.provider-branch-editor')

            ?.remove();

        },

      );

    });

}





function useBrowserLocation(

  editor,

  button,

) {

  if (!navigator.geolocation) {

    setBranchLocationStatus(

      editor,

      'Location services are not supported by this browser.',

      'error',

    );

    return;

  }



  button.disabled = true;

  button.textContent = 'Detecting Location...';



  setBranchLocationStatus(

    editor,

    'Detecting this device location...',

    'pending',

  );



  navigator.geolocation.getCurrentPosition(

    async (position) => {

      const latitude =

        position.coords.latitude;



      const longitude =

        position.coords.longitude;



      const latitudeInput =

        editor.querySelector(

          '.branch-latitude-input',

        );



      const longitudeInput =

        editor.querySelector(

          '.branch-longitude-input',

        );



      const addressInput =

        editor.querySelector(

          '.branch-address-input',

        );



      latitudeInput.value = latitude;

      longitudeInput.value = longitude;



      try {

        setBranchLocationStatus(

          editor,

          'Location found. Looking up the address...',

          'pending',

        );



        const detectedAddress =

          await reverseGeocodeCoordinates(

            latitude,

            longitude,

          );



        if (detectedAddress) {

          addressInput.value =

            detectedAddress;



          editor.dataset.resolvedAddress =

            detectedAddress;

        } else {

          editor.dataset.resolvedAddress =

            addressInput.value.trim();

        }



        editor.dataset.locationDirty =

          'false';



        setBranchLocationStatus(

          editor,

          'Location detected. You can edit the address if needed.',

          'success',

        );

      } catch (error) {

        console.error(

          'Reverse geocoding error:',

          error,

        );



        editor.dataset.resolvedAddress =

          addressInput.value.trim();



        editor.dataset.locationDirty =

          'false';



        setBranchLocationStatus(

          editor,

          'Coordinates detected. The address could not be filled automatically, so please enter it manually.',

          'pending',

        );

      } finally {

        button.disabled = false;

        button.textContent =

          'Use Current Location';

      }

    },

    (error) => {

      console.error(

        'Browser geolocation error:',

        error,

      );



      setBranchLocationStatus(

        editor,

        'Unable to detect the current location. Check browser location permission or enter the address manually.',

        'error',

      );



      button.disabled = false;

      button.textContent =

        'Use Current Location';

    },

    {

      enableHighAccuracy: true,

      timeout: 10000,

      maximumAge: 30000,

    },

  );

}





async function resolveBranchLocationsFromForm(

  branchList,

) {

  const editors = Array.from(

    branchList.querySelectorAll(

      '.provider-branch-editor',

    ),

  );



  for (const editor of editors) {

    const addressInput =

      editor.querySelector(

        '.branch-address-input',

      );



    const latitudeInput =

      editor.querySelector(

        '.branch-latitude-input',

      );



    const longitudeInput =

      editor.querySelector(

        '.branch-longitude-input',

      );



    const address =

      addressInput.value.trim();



    if (!address) {

      throw new Error(

        'Please enter the address for every branch.',

      );

    }



    const latitude =

      parseCoordinate(

        latitudeInput.value,

      );



    const longitude =

      parseCoordinate(

        longitudeInput.value,

      );



    const needsGeocoding =

      editor.dataset.locationDirty === 'true' ||

      !Number.isFinite(latitude) ||

      !Number.isFinite(longitude);



    if (!needsGeocoding) {

      continue;

    }



    setBranchLocationStatus(

      editor,

      'Locating this branch address...',

      'pending',

    );



    const location =

      await geocodeBranchAddress(

        address,

      );



    latitudeInput.value =

      location.latitude;



    longitudeInput.value =

      location.longitude;



    editor.dataset.resolvedAddress =

      address;



    editor.dataset.locationDirty =

      'false';



    setBranchLocationStatus(

      editor,

      'Address located successfully.',

      'success',

    );

  }

}





async function reverseGeocodeCoordinates(

  latitude,

  longitude,

) {

  const cacheKey =

    `reverse:${latitude.toFixed(6)},${longitude.toFixed(6)}`;



  if (geocodingCache.has(cacheKey)) {

    return geocodingCache.get(cacheKey);

  }



  const url = new URL(

    `${NOMINATIM_BASE_URL}/reverse`,

  );



  url.searchParams.set(

    'format',

    'jsonv2',

  );



  url.searchParams.set(

    'lat',

    String(latitude),

  );



  url.searchParams.set(

    'lon',

    String(longitude),

  );



  url.searchParams.set(

    'addressdetails',

    '1',

  );



  url.searchParams.set(

    'zoom',

    '18',

  );



  const data =

    await fetchNominatimJson(url);



  const address =

    data?.display_name?.trim() || '';



  geocodingCache.set(

    cacheKey,

    address,

  );



  return address;

}





async function geocodeBranchAddress(

  address,

) {

  const normalised =

    normaliseAddress(address);



  const cacheKey =

    `search:${normalised}`;



  if (geocodingCache.has(cacheKey)) {

    return geocodingCache.get(cacheKey);

  }



  const url = new URL(

    `${NOMINATIM_BASE_URL}/search`,

  );



  url.searchParams.set(

    'format',

    'jsonv2',

  );



  url.searchParams.set(

    'q',

    address,

  );



  url.searchParams.set(

    'limit',

    '1',

  );



  url.searchParams.set(

    'addressdetails',

    '1',

  );



  const results =

    await fetchNominatimJson(url);



  if (!Array.isArray(results) || results.length === 0) {

    throw new Error(

      `Unable to locate the address: ${address}`,

    );

  }



  const latitude =

    Number(results[0].lat);



  const longitude =

    Number(results[0].lon);



  if (

    !Number.isFinite(latitude) ||

    !Number.isFinite(longitude)

  ) {

    throw new Error(

      `Invalid location returned for: ${address}`,

    );

  }



  const location = {

    latitude,

    longitude,

  };



  geocodingCache.set(

    cacheKey,

    location,

  );



  return location;

}





async function fetchNominatimJson(

  url,

) {

  const elapsed =

    Date.now() - lastNominatimRequestAt;



  const waitMs =

    Math.max(

      0,

      NOMINATIM_MIN_INTERVAL_MS - elapsed,

    );



  if (waitMs > 0) {

    await new Promise(

      (resolve) => setTimeout(resolve, waitMs),

    );

  }



  lastNominatimRequestAt =

    Date.now();



  const response = await fetch(

    url,

    {

      headers: {

        Accept: 'application/json',

      },

    },

  );



  if (!response.ok) {

    throw new Error(

      'The address lookup service is temporarily unavailable.',

    );

  }



  return response.json();

}





function setBranchLocationStatus(

  editor,

  text,

  state = '',

) {

  const status =

    editor.querySelector(

      '.branch-location-status',

    );



  const statusText =

    status?.querySelector(

      '.branch-location-status-text',

    );



  if (!status || !statusText) {

    return;

  }



  status.classList.remove(

    'success',

    'pending',

    'error',

  );



  if (state) {

    status.classList.add(state);

  }



  statusText.textContent = text;

}





function normaliseAddress(

  value,

) {

  return value

    .trim()

    .replace(/\s+/g, ' ')

    .toLowerCase();

}





function parseCoordinate(

  value,

) {

  const text =

    String(value ?? '').trim();



  if (!text) {

    return Number.NaN;

  }



  return Number(text);

}





function readBranchesFromForm() {

  return Array.from(

    document.querySelectorAll(

      '.provider-branch-editor',

    ),

  ).map((editor) => ({

    name:

      editor

        .querySelector('.branch-name-input')

        .value

        .trim(),



    address:

      editor

        .querySelector('.branch-address-input')

        .value

        .trim(),



    latitude:

      parseCoordinate(

        editor

          .querySelector('.branch-latitude-input')

          .value,

      ),



    longitude:

      parseCoordinate(

        editor

          .querySelector('.branch-longitude-input')

          .value,

      ),



    active: true,

  }));

}





function buildDocumentInput({

  id,

  label,

  required,

  existingDocument,

}) {

  const documentCode =

    id.startsWith('ssm')

      ? 'SSM'

      : id.startsWith('kpdn')

        ? 'KPDN'

        : 'ST';



  return `

    <div class="verification-upload-card ${existingDocument ? 'has-existing-file' : ''}">



      <div class="verification-document-main">

        <div class="verification-document-badge">

          ${escapeHtml(documentCode)}

        </div>



        <div class="verification-document-copy">

          <div class="verification-document-title-row">

            <strong>

              ${escapeHtml(label)}

            </strong>



            <span class="verification-required-badge">

              ${existingDocument ? 'Uploaded' : 'Required'}

            </span>

          </div>



          ${existingDocument

            ? `

              <span class="uploaded-document-note verification-file-name">

                ${escapeHtml(existingDocument.originalName || 'Uploaded document')}

              </span>

            `

            : `

              <span class="verification-file-name">

                No new file selected

              </span>

            `}

        </div>

      </div>



      <div class="verification-file-control">

        <input

          class="verification-file-input"

          id="${escapeAttribute(id)}"

          type="file"

          accept="application/pdf,image/jpeg,image/png"

          ${required ? 'required' : ''}

        />

      </div>



    </div>

  `;

}



function getSelectedFile(id) {

  const input =

    document.querySelector(

      `#${id}`,

    );



  return input?.files?.[0] || null;

}





function buildReviewSection(

  title,

  items,

) {

  const safeItems = items

    .filter(Boolean)

    .map((item) => escapeHtml(String(item)));



  return `

    <section class="registration-review-section">

      <h3>${escapeHtml(title)}</h3>



      ${safeItems.length > 0

        ? `

            <ul>

              ${safeItems.map((item) => `

                <li>${item}</li>

              `).join('')}

            </ul>

          `

        : `

            <p>No information supplied.</p>

          `}

    </section>

  `;

}





function normaliseExistingCategoryIds(

  providerProfile,

) {

  const rawCategoryIds =

    Array.isArray(providerProfile.categoryIds)

      ? providerProfile.categoryIds

      : Array.isArray(providerProfile.servicesOffered)

        ? providerProfile.servicesOffered

        : [];



  return rawCategoryIds.map(

    (categoryId) =>

      categoryId === 'lpg'

        ? 'gas_replacement'

        : categoryId,

  );

}





function clearMessage(message) {

  message.textContent = '';

  message.classList.remove('error');

}





function showError(

  message,

  text,

) {

  message.textContent = text;

  message.classList.add('error');

}





function escapeHtml(value) {

  return String(value)

    .replaceAll('&', '&amp;')

    .replaceAll('<', '&lt;')

    .replaceAll('>', '&gt;')

    .replaceAll('"', '&quot;')

    .replaceAll("'", '&#039;');

}





function escapeAttribute(value) {

  return escapeHtml(value);

}


// =========================
// NEW PROVIDER: ACCOUNT STAGE
// =========================

// Matches the character categories selected in Firebase Password Policy.
const PASSWORD_SPECIAL_CHARACTERS =
  "^$*.[]{}()?\"!@#%&/\\,><':;|_~`";

function getMissingPasswordRequirements(password) {
  const missing = [];

  if (password.length < 8) {
    missing.push('at least 8 characters');
  }

  if (!/[A-Z]/.test(password)) {
    missing.push('one uppercase letter');
  }

  if (!/[a-z]/.test(password)) {
    missing.push('one lowercase letter');
  }

  if (!/[0-9]/.test(password)) {
    missing.push('one number');
  }

  const hasSpecialCharacter = [...password].some(
    (character) => PASSWORD_SPECIAL_CHARACTERS.includes(character),
  );

  if (!hasSpecialCharacter) {
    missing.push('one special character');
  }

  return missing;
}

function showProviderAccountStep(
  app,
  {
    onBackToLogin,
    onAccountCreated,
    existingUser = null,
  },
) {
  app.innerHTML = `
    <main class="login-page">
      <section class="login-panel">

        <div class="brand">
          <div class="brand-icon">H</div>
          <span class="brand-name">
            HomeAssist
          </span>
        </div>

        <div class="login-content">
          <p class="portal-label">
            PROVIDER REGISTRATION
          </p>

          <h1>
            ${
              existingUser
                ? 'Complete your account setup'
                : 'Create provider account'
            }
          </h1>

          <p class="subtitle">
            ${
              existingUser
                ? 'Finish setting up your provider profile before continuing.'
                : 'Create login credentials before entering business information.'
            }
          </p>

          <form id="provider-account-form">

            <div class="form-group">
              <label for="provider-account-name">
                Your Name
              </label>

              <input
                id="provider-account-name"
                type="text"
                maxlength="80"
                required
                autocomplete="name"
                value="${
                  escapeAttribute(
                    existingUser?.displayName || '',
                  )
                }"
                placeholder="Name of account holder"
              />
            </div>

            <div class="form-group">
              <label for="provider-account-email">
                Email Address
              </label>

              <input
                id="provider-account-email"
                type="email"
                required
                autocomplete="email"
                ${
                  existingUser
                    ? 'disabled'
                    : ''
                }
                value="${
                  escapeAttribute(
                    existingUser?.email || '',
                  )
                }"
                placeholder="example@gmail.com"
              />
            </div>

            ${
              existingUser
                ? ''
                : `
                  <div class="form-group">
                    <label for="provider-account-password">
                      Password
                    </label>

                    <input
                      id="provider-account-password"
                      type="password"
                      autocomplete="new-password"
                      aria-describedby="provider-password-requirements"
                      required
                      placeholder="Enter a secure password"
                    />
                    <p
                      id="provider-password-requirements"
                      style="margin: 6px 0 0; color: #64748b; font-size: 12px; line-height: 1.4;"
                    >
                      At least 8 characters, with uppercase, lowercase,
                      a number and a special character.
                    </p>
                  </div>

                  <div class="form-group">
                    <label for="provider-account-confirm">
                      Confirm Password
                    </label>

                    <input
                      id="provider-account-confirm"
                      type="password"
                      autocomplete="new-password"
                      required
                      placeholder="Re-enter password"
                    />
                  </div>
                `
            }

            <button
              type="submit"
              class="primary-button"
              id="provider-account-submit"
            >
              ${
                existingUser
                  ? 'Finish Account Setup'
                  : 'Create Account'
              }
            </button>

            <p
              class="form-message"
              id="provider-account-message"
              role="status"
              aria-live="polite"
            ></p>

          </form>

          <button
            type="button"
            class="text-button"
            id="provider-account-back"
            style="margin-top: 18px;"
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
          <div class="info-icon">✓</div>

          <h2>
            Become a HomeAssist provider.
          </h2>

          <p>
            Verify your email, complete your
            business application, and await
            administrator approval before
            serving customers.
          </p>
        </div>
      </section>
    </main>
  `;

  const form =
    app.querySelector(
      '#provider-account-form',
    );

  const nameInput =
    app.querySelector(
      '#provider-account-name',
    );

  const emailInput =
    app.querySelector(
      '#provider-account-email',
    );

  const passwordInput =
    app.querySelector(
      '#provider-account-password',
    );

  const confirmInput =
    app.querySelector(
      '#provider-account-confirm',
    );

  const submitButton =
    app.querySelector(
      '#provider-account-submit',
    );

  const message =
    app.querySelector(
      '#provider-account-message',
    );

  let createdAuthAccount =
    Boolean(existingUser);

  app
    .querySelector('#provider-account-back')
    .addEventListener(
      'click',
      () => {
        onBackToLogin();
      },
    );

  form.addEventListener(
    'submit',
    async (event) => {
      event.preventDefault();

      message.textContent = '';
      message.classList.remove('error');

      const displayName =
        nameInput.value.trim();

      const email =
        emailInput.value.trim().toLowerCase();

      if (displayName.length < 2) {
        message.textContent =
          'Please enter your full name.';

        message.classList.add('error');
        return;
      }

      // Validate only when a new Firebase Auth account is being created.
      // A retry of provider profile setup does not ask for the password.
      if (!createdAuthAccount) {
        const missingRequirements =
          getMissingPasswordRequirements(passwordInput.value);

        if (missingRequirements.length > 0) {
          message.textContent =
            'Password must include: ' +
            missingRequirements.join(', ') + '.';

          message.classList.add('error');
          return;
        }
      }

      if (
        !createdAuthAccount &&
        passwordInput.value !== confirmInput.value
      ) {
        message.textContent =
          'The passwords do not match.';

        message.classList.add('error');
        return;
      }

      submitButton.disabled = true;

      submitButton.textContent =
        createdAuthAccount
          ? 'Finishing setup...'
          : 'Creating account...';

      try {
        if (createdAuthAccount) {
          await finishProviderAccountSetup(
            displayName,
          );
        } else {
          try {
            await createProviderAccount({
              displayName,
              email,
              password: passwordInput.value,
            });

            createdAuthAccount = true;
          } catch (error) {
            // Firebase Auth might have created
            // the account before profile setup failed.
            // In that case, retry profile setup
            // rather than creating another account.
            const current = auth.currentUser;

            if (
              current &&
              current.email?.toLowerCase() === email
            ) {
              createdAuthAccount = true;
            }

            throw error;
          }
        }

        await onAccountCreated();
      } catch (error) {
        console.error(
          'Provider account setup failed:',
          error,
        );

        message.textContent =
          createdAuthAccount
            ? 'Account created, but setup could not finish. '
                + 'Click again to retry. '
                + (error.message || '')
            : friendlyProviderSignupError(error);

        message.classList.add('error');
      } finally {
        if (app.contains(submitButton)) {
          submitButton.disabled = false;

          submitButton.textContent =
            createdAuthAccount
              ? 'Finish Account Setup'
              : 'Create Account';
        }
      }
    },
  );
}


// =========================
// FRIENDLY SIGN-UP ERRORS
// =========================

function friendlyProviderSignupError(error) {
  switch (error?.code) {
    case 'auth/email-already-in-use':
      return (
        'This email is already registered. '
        + 'Please sign in instead.'
      );

    case 'auth/invalid-email':
      return 'Please enter a valid email address.';

    case 'auth/weak-password':
      return 'Please choose a stronger password.';

    default:
      return (
        error?.message ||
        'Unable to create the account. Please try again.'
      );
  }
}


// =========================
// PROVIDER: EMAIL VERIFICATION
// =========================

function showProviderEmailVerificationPage(
  app,
  {
    email,
    onCheckVerification,
    onResendVerification,
    onSignOut,
  },
) {
  app.innerHTML = `
    <main class="login-page">
      <section class="login-panel">

        <div class="brand">
          <div class="brand-icon">H</div>
          <span class="brand-name">
            HomeAssist
          </span>
        </div>

        <div class="login-content">

          <p class="portal-label">
            VERIFY YOUR EMAIL
          </p>

          <h1>
            Check your inbox
          </h1>

          <p class="subtitle">
            Use the verification link sent to
            <strong id="verification-address"></strong>.
            Then return here to continue registration.
          </p>

          <button
            type="button"
            class="primary-button"
            id="provider-check-verification"
          >
            I've Verified My Email
          </button>

          <button
            type="button"
            class="secondary-button"
            id="provider-resend-verification"
            style="margin-top: 12px;"
          >
            Resend Verification Email
          </button>

          <p
            class="form-message"
            id="provider-verification-message"
            role="status"
            aria-live="polite"
          ></p>

          <button
            type="button"
            class="text-button"
            id="provider-verification-signout"
            style="margin-top: 18px;"
          >
            Sign Out
          </button>
        </div>

        <p class="footer-text">
          HomeAssist Service Platform
        </p>

      </section>

      <section class="information-panel">
        <div class="information-content">

          <div class="info-icon">✓</div>

          <h2>
            Secure provider registration
          </h2>

          <p>
            Once email verification is complete,
            you can enter your business details
            and submit them for administrator review.
          </p>

        </div>
      </section>
    </main>
  `;

  app.querySelector(
    '#verification-address',
  ).textContent = email || '';

  const checkButton =
    app.querySelector(
      '#provider-check-verification',
    );

  const resendButton =
    app.querySelector(
      '#provider-resend-verification',
    );

  const message =
    app.querySelector(
      '#provider-verification-message',
    );

  checkButton.addEventListener(
    'click',
    async () => {
      checkButton.disabled = true;

      message.classList.remove('error');

      message.textContent =
        'Checking verification...';

      try {
        const verified =
          await onCheckVerification();

        if (!verified) {
          message.textContent =
            'Your email is not verified yet. '
            + 'Check your inbox and try again.';
        }
      } catch (error) {
        message.textContent =
          error.message ||
          'Unable to check verification.';

        message.classList.add('error');
      } finally {
        checkButton.disabled = false;
      }
    },
  );

  resendButton.addEventListener(
    'click',
    async () => {
      resendButton.disabled = true;

      message.classList.remove('error');

      message.textContent =
        'Sending verification email...';

      try {
        await onResendVerification();

        message.textContent =
          'Verification email requested. '
          + 'Please check your inbox and spam folder.';
      } catch (error) {
        message.textContent =
          error.message ||
          'Unable to resend verification email.';

        message.classList.add('error');
      } finally {
        resendButton.disabled = false;
      }
    },
  );

  app
    .querySelector(
      '#provider-verification-signout',
    )
    .addEventListener(
      'click',
      async () => {
        await onSignOut();
      },
    );
}

export {
  showProviderRegistrationPage,
  showProviderAccountStep,
  showProviderEmailVerificationPage,
};

