# Shejire — App Review submission package

Build: **1.0.0 (4)**
Bundle ID: **kz.hexnet.geneology**

## Reply to App Review / Review Notes

Paste the text below both into the reply to App Review and into the **App Review Information → Notes** field. Attach the screen recording to the reply.

---

Hello App Review Team,

Thank you for your guidance. We have tested the app again and are providing the requested information below.

1. SCREEN RECORDING

We attached a screen recording from a physical iPhone 14 Pro Max running iOS 26.5. It begins with a fresh launch and demonstrates the information screen, genealogy navigation, person details, PDF import and page-by-page reading, local PDF deletion, and administrator sign-in.

The app has no purchases, subscriptions, advertising, tracking, public registration, or general-user account deletion flow. General users cannot upload or publish server content. The system Files picker requires no contacts, location, camera, or microphone access.

2. TEST DEVICES

- Physical iPhone 14 Pro Max — iOS 26.5 (23F77)
- iPhone 17 Simulator — iOS 26.5

Build 4 supports iPhone only. iPad is not included in the supported device family.

3. PURPOSE AND TARGET AUDIENCE

Shejire is an educational reference app about Kazakh genealogy and cultural heritage. It helps Kazakh-speaking families, students, and people interested in family history navigate a large genealogy tree, view biographical details, learn about “shejire,” and read related PDF reference materials.

4. ACCESS AND SETUP INSTRUCTIONS

No account or setup is required for the normal user experience:

1. Launch the app and open “Басты” to view the introductory information.
2. Open “Шежіре” and tap a person or expand a branch to navigate the genealogy tree and view details.
3. Open “PDF.” The administrator-curated shared catalog, when populated, is free. For local reading, tap “Жеке PDF таңдау,” choose a PDF in Files, open it, and swipe horizontally. Local PDFs remain on-device and are never uploaded.
4. The shield icon opens an optional administrator sign-in used only to maintain genealogy records and the shared catalog. The review credentials are supplied separately in App Review Information. There is no public registration flow.

No special settings or sample file are required; any valid PDF works for local import.

5. EXTERNAL SERVICES AND PLATFORMS

- Supabase, hosted at genealogy.projectmanager.kz: PostgreSQL genealogy data, administrator authentication, shared-book metadata, and PDF storage.
- Apple system Files/document picker: optional selection of a private local PDF.

The app uses no AI services, payment processors, advertising SDKs, analytics SDKs, or third-party social login.

6. REGIONAL DIFFERENCES

The app functions consistently in all available regions, with no regional feature, pricing, or content differences. The interface is primarily in Kazakh because of its cultural focus.

7. REGULATED SERVICES AND THIRD-PARTY MATERIAL

The app provides no regulated services. Genealogy entries are factual names and family relationships curated in our database; no third-party content service is accessed at runtime.

Only an authorized administrator can manage the shared book catalog; end users cannot upload or publish books. All shared books are free. At the time of this submission, the production shared catalog contains no protected third-party books. Users may optionally select their own PDF files for private on-device viewing, and those files are never uploaded or shared by the app.

Please let us know if any additional information is required.

---

## App Review credentials

Do not commit the password to this repository. Enter the current non-expiring review credentials in App Store Connect:

- Username: `test@gmail.com`
- Password: enter the current administrator review password in the password field or Notes immediately before submission.

The account currently has administrator permissions, including modification and deletion. Avoid demonstrating destructive actions in the recording. A dedicated non-destructive review account is preferable for future submissions.

## Screen-recording script

Record in portrait orientation on the physical iPhone 14 Pro Max running iOS 26.5. Turn on Do Not Disturb and ensure no personal notifications appear.

1. Start recording before launching Shejire, then launch it from the Home Screen.
2. Show “Басты” and scroll through the informational content.
3. Open “Шежіре,” expand a branch/person, and open one person's details.
4. Open “PDF.” If the shared catalog is empty, let the empty state remain visible briefly.
5. Tap “Жеке PDF таңдау,” select a harmless sample PDF in Files, and open it.
6. Swipe horizontally through several pages, tap the page counter, jump to another page, return to the library, and delete the local PDF.
7. Tap the shield icon, sign in with the review administrator account, show the paginated list and search, but do not add, edit, or delete production data.
8. Sign out and stop recording.

Before attaching, watch the entire recording and confirm that the password, notifications, personal filenames, and unrelated personal data are not visible.

## App Store Connect submission checklist

- Upload and select build **1.0.0 (4)**. Do not select superseded builds 2 or 3.
- Confirm the Privacy Policy URL displays the updated policy dated 28 August 2026.
- Enter a real review contact name, monitored email, and phone number with country code.
- Add the non-expiring administrator credentials to App Review Information.
- Paste the Review Notes above.
- Attach the physical-device screen recording to the App Review reply.
- Confirm screenshots show the actual information, genealogy, and PDF screens—not only the splash or sign-in screen.
- Confirm App Privacy answers match the updated privacy policy and actual Supabase use.
- Confirm the production shared catalog contains no protected third-party books before submitting.
- Select build 4, save, choose **Add for Review**, then **Submit for Review**.

## Recommended App Privacy answers

Select **Yes, we collect data from this app** because the optional administrator account sends data to Supabase.

- **Contact Info → Email Address:** App Functionality; linked to identity; not used for tracking.
- **Identifiers → User ID:** App Functionality; linked to identity; not used for tracking.
- **User Content → Other User Content:** App Functionality; linked to the administrator account; not used for tracking. This covers genealogy records entered through the administrator interface.

Do not declare locally imported PDFs as collected: they remain on-device. Do not select advertising, purchases, contacts, location, photos, audio, product interaction, or crash analytics unless the production backend or another SDK actually stores such data. If reverse-proxy/Supabase logs retain IP addresses or search terms beyond servicing a request, disclose those retained data types as well.

## Export compliance

The app uses ordinary HTTPS for Supabase and no proprietary/non-exempt encryption. Build 4 contains `ITSAppUsesNonExemptEncryption = NO`.
