# Tidy — iPhone Cleanup App: Design Spec

Date: 2026-10-20 · Status: awaiting owner review

## 1. Goal

A personal iPhone app, **Tidy**, that the owner opens every few weeks, swipes for ~5 minutes,
and gets back noticeable space — without ever losing something they wanted.

**Owner decisions (confirmed):**
- iPhone; for the owner's phone only; no App Store; free Apple ID only (no $99 program).
- No Mac available (tabled). Build on GitHub Actions macOS runners; install via SideStore.
- Covers photos & videos, contacts, files, plus a guided checklist for apps and messages.
- Review-and-approve only. Nothing is deleted without the owner confirming.
- Review UI: swipe cards.
- Photo library size: 5,000–30,000 items.
- Everything is processed on the device. No accounts, no network calls, no analytics.
- Repo: `C:\Users\jbman\Projects\phone-cleaner`, public GitHub repo (unlimited free macOS builds;
  the code holds no personal data).

**Out of scope:** auto-deletion, cloud sync, App Store distribution, iPad layout, and anything
iOS forbids (other apps' caches, the installed-app list, reading Messages).

## 2. Build & install pipeline

- **Project generation:** XcodeGen `project.yml` → `.xcodeproj` is generated in CI and not committed.
- **Language/UI:** Swift 6, SwiftUI, minimum iOS 17.
- **CI:** GitHub Actions on `macos-latest`.
  - On every push to `main`: run unit tests on an iOS simulator, then build an unsigned `Tidy.ipa`
    (`CODE_SIGNING_ALLOWED=NO`, `Payload/Tidy.app` zipped).
  - Upload it as a workflow artifact, and attach it to a GitHub Release when a `v*` tag is pushed.
- **Install:** SideStore on the iPhone signs the IPA with the owner's free Apple ID and refreshes it
  every 7 days over Wi-Fi. Refreshing keeps app data.
- **One-time setup:** a step-by-step guide at `docs/install-guide.md` for SideStore setup from the
  owner's Windows 11 PC.
- **Free-signing limits:** no iCloud/CloudKit, no push notifications, no App Groups dependency.
  Local notifications are allowed and are what Tidy uses.
- **Bundle ID:** `com.jbman03.tidy`. SideStore may append a suffix, and the app must not depend
  on the exact ID.

## 3. Architecture

Every unit has one job. Scanners never delete, and only the Cleaner deletes.

| Unit | Job | Depends on |
|---|---|---|
| `Scanners/*` | Find candidates in one area and emit `ReviewItem`s | PhotoKit / Contacts / FileManager, `Memory` |
| `Review` | Shared swipe-card deck. Collects keep/delete/skip decisions into a queue | `ReviewItem` |
| `Cleaner` | Executes the confirmed queue. Takes backups first where needed | PhotoKit, Contacts, FileManager, `Backup` |
| `Memory` | Persists "kept forever", "not the same person", scan progress, settings | SwiftData (local) |
| `Backup` | Contacts `.vcf` snapshots and restore; Tidy Trash bookkeeping | Contacts, FileManager |
| `Home` | Space-to-free total, area cards, signature countdown | Scanners (summaries), `SigningInfo` |
| `Checklist` | Tidy-up steps for apps and messages; monthly reset | `Memory` |
| `Reminders` | Monthly local notification | UserNotifications |
| `SigningInfo` | Reads `embedded.mobileprovision` expiration date | Bundle |

`ReviewItem` is a common model: id, area, title, size in bytes, date, a preview provider, and for
groups the members plus a suggested keeper.

Pure logic lives in a separate `TidyCore` Swift package target with no UI or framework I/O, so it
is unit-testable on CI. That covers phone normalization, duplicate grouping, best-shot scoring,
contact merge results, trash expiry, and threshold filtering.

## 4. Photos & videos

**Scanners**
- **Old screenshots:** `mediaSubtypes.photoScreenshot` older than N days (default 30). Newest first.
- **Big videos:** videos whose resource file size is ≥ M MB (default 100). Biggest first.
- **Exact duplicates:** same pixel dimensions plus an identical perceptual hash of a 64×64 thumbnail,
  confirmed by a matching Vision feature-print distance of about 0.
- **Near-duplicates:** photos taken within 5 minutes of each other whose Vision
  `VNGenerateImageFeaturePrintRequest` distance is below a threshold (tuned on device; starting value
  0.35). Clustered by single-link grouping within the time window.
- **Blurry/junk:** Vision image-aesthetics scoring (`CalculateImageAestheticsScoresRequest`,
  iOS 18+). Flag `isUtility` shots and those with a low overall score. On iOS 17, fall back to a
  Laplacian-variance blur measure on the thumbnail.

**Best shot in a group:** favorited or edited beats everything. Then the highest sharpness score,
then the highest resolution, then the newest. The owner can tap a different keeper.

**Always protected (never suggested):** favorites, photos in user-created albums (on by default,
can be turned off), anything from the last 7 days, and items marked "keep forever."

**Scanning:** works from ~300px thumbnails via `PHCachingImageManager`, in batches of 200. A
checkpoint is written to `Memory` after each batch, so an interrupted scan resumes. Re-scans only
process assets added since the last scan (by creation date / local identifier set). Progress is
shown on the area card. The first full scan target is under 5 minutes for 30k items on a recent
iPhone.

**iCloud Photos detection:** if any asset reports a cloud-shared or iCloud-only resource
(`PHAssetResource` locally-available checks), show "Deleting also removes these from iCloud and
your other devices." Otherwise show "Deletes from this iPhone."

## 5. Swipe review (shared)

- Left = delete, right = keep (remembered forever), up = skip for now. An Undo button reverses the
  last swipe.
- Group cards show the keeper large and the others as thumbnails. Swiping left deletes all but the
  keeper.
- Decisions queue up and nothing is deleted while swiping. A bottom bar reads
  "Delete 47 items · frees 2.1 GB."
- **Confirm:**
  - Photos: `PHAssetChangeRequest.deleteAssets`, which shows iOS's own confirm and sends items to
    Recently Deleted (30 days).
  - Contacts and files: Tidy's own confirm sheet.
- If the delete fails or is cancelled, the queue is kept so the owner can retry.

## 6. Contacts

- **Duplicates:** contacts sharing a normalized phone (digits only; leading country code `1`
  dropped for US numbers), a lowercased email, or a name similarity ≥ 0.9 (normalized
  Levenshtein on given + family name).
- **Merge card:** the duplicates side by side with the merged result previewed. Right = merge,
  left = "not the same person" (pair remembered forever), up = skip.
- **Merge result:** the contact with the most fields is the base. It takes the union of phones,
  emails, postal addresses and URLs (deduplicated by normalized value); notes are joined with
  a blank line; the base's photo is kept, or the first available one. The others are then deleted.
- **Empty contacts:** a pile of contacts with no phone and no email.
- **Backup:** before any contact change, export all contacts to
  `Documents/Backups/contacts-YYYYMMDD-HHMM.vcf` (visible in Files → On My iPhone → Tidy).
  Settings → Restore re-imports a chosen backup. Backups older than 90 days are pruned.

## 7. Files

- The owner adds folders via `UIDocumentPickerViewController` (folder mode). Access is remembered
  with security-scoped bookmarks.
- **Scanners:**
  - big files (≥ 50 MB)
  - old files (modified more than 365 days ago)
  - duplicate files (same size, then SHA-256 match)
- Cards show a QuickLook thumbnail, name, size, date and path.
- **Delete:** move to `Tidy Trash/` in that folder's root, with a record in `Memory`.
  - Items older than 30 days are permanently removed on the next launch.
  - "Empty Tidy Trash now" frees the space immediately.
  - "Restore" moves an item back to its original path.

## 8. Home, checklist, reminders

- **Home:**
  - "You could free X GB" (the sum of current candidates)
  - area cards showing count + size + scan progress
  - the Checklist entry
  - the signature line: "Signature renews in N days," turning to a warning when under 2 days
    ("Open SideStore to refresh")
- **Checklist items** (each shows the exact Settings path and an "Open Settings" button, which opens
  Settings because iOS doesn't allow deep links to specific pages; ticks reset on the 1st of each
  month):
  1. Turn on Offload Unused Apps: Settings → Apps → App Store → Offload Unused Apps.
  2. Review the biggest apps: Settings → General → iPhone Storage.
  3. Keep Messages for 1 year: Settings → Apps → Messages → Keep Messages.
  4. Review large message attachments: Settings → General → iPhone Storage → Messages.
  5. Empty Recently Deleted in Photos (once sure).
  6. Clear Safari history & website data: Settings → Apps → Safari.
- **Reminder:** one local notification a month: "Time to tidy — about X GB to free." The owner picks
  the day of month and time (default: the 1st at 10:00). It can be turned off. X is the last known
  total.

## 9. Permissions & errors

- Photos: request read/write. With limited access, work with the allowed set and show a banner
  offering "Allow full access."
- Contacts: request access. If denied, show an explainer with an Open Settings button.
- Files: no permission prompt; access comes per folder through the picker. If a bookmark goes
  stale, prompt the owner to re-pick that folder.
- Notifications: request only when the owner turns the reminder on.
- Every failure leaves data untouched and the queue intact.

## 10. Testing

- **Unit tests (`TidyCore`, run in CI):**
  - phone/email normalization
  - contact duplicate detection and merge result
  - near-duplicate clustering given feature-print distances
  - best-shot ordering
  - threshold filters
  - trash expiry
  - "keep forever" suppression
  - scan checkpoint and resume logic
- **On-device checks:** a short "try this on your phone" checklist at the end of every stage.
- CI must be green before a build is considered done.

## 11. Build stages (each one ends installable on the phone)

1. **Pipeline + skeleton:** XcodeGen project, CI test + IPA build, install guide, and an app with the
   Home screen, signature countdown and placeholder cards. Proves the no-Mac install route works.
2. **Photos I:** screenshots + big videos scanners, the swipe deck, Cleaner for photos, "keep" memory.
3. **Photos II:** exact duplicates, near-duplicates, blurry, group cards, best-shot pick, iCloud
   warning.
4. **Contacts:** duplicates, merge, empty contacts, backup/restore.
5. **Files + checklist + reminders:** folder picking, file scanners, Tidy Trash, checklist, monthly
   reminder, and the final Home totals.
