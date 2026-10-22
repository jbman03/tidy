# Installing Tidy on your iPhone (from a Windows PC)

Tidy isn't on the App Store, so it's installed with **SideStore**, a free tool that signs apps
with your own Apple ID. You set SideStore up once from your PC. After that, everything happens on
the phone.

Steps checked against SideStore's official docs (docs.sidestore.io) on 2026-10-22. If a screen
looks different, their docs win.

## What you need

- Your iPhone (iOS 15 or newer, with a passcode) and its USB cable
- Your Windows 11 PC (64-bit)
- Your Apple ID (free; no developer program needed)
- Wi-Fi on the phone (refreshing doesn't work over mobile data)
- About 30–45 minutes the first time

## Part 1: Install SideStore (one time)

1. **On the PC:** install **iTunes** directly from Apple's website (recommended over the Microsoft
   Store version). If it gives trouble, the **Apple Devices** app from the Microsoft Store works
   too.
2. **On the PC:** download **iloader** from the SideStore install page (the `.msi` installer is
   recommended) and run it.
3. **On the iPhone:** install **LocalDevVPN** from the App Store. Open it and tap **Connect**. If
   asked, tap **Allow** and enter your passcode.
4. Plug the iPhone into the PC. If the phone asks, tap **Trust This Computer** and enter your
   passcode.
5. **In iloader:**
   1. Sign in with your Apple ID. It's case-sensitive, so type it exactly.
   2. Select your iPhone.
   3. Click **Install SideStore (Stable)**.
6. **On the iPhone, trust the app:** Settings → General → **VPN & Device Management** → under
   *Developer App*, tap your Apple ID → **Trust**, then confirm.
7. **On the iPhone, turn on Developer Mode:** Settings → **Privacy & Security** → scroll to the
   bottom → **Developer Mode** → on. The phone restarts. After it restarts, confirm **Turn On**.
8. **First launch:**
   1. Open LocalDevVPN and **Connect**.
   2. Open **SideStore** and sign in with the same Apple ID.
   3. Go to **My Apps** and tap the **7 DAYS** counter next to SideStore to refresh it once.
   4. If asked to revoke or create a certificate, tap **Yes** / **Refresh Now**.

You can unplug the phone now. You won't need the PC again unless something breaks (see
Troubleshooting).

## Part 2: Install Tidy

1. On the iPhone, open Safari and go to
   **https://github.com/jbman03/tidy/releases/latest**.
2. Tap **Tidy.ipa** to download it. It goes to Files → Downloads.
3. Open LocalDevVPN and **Connect**.
4. Open SideStore → **My Apps** → tap **+** (top corner) → choose **Tidy.ipa** from Downloads.
5. Wait for it to finish. **Tidy** appears on your home screen.

**Updating Tidy later:** download the newer `Tidy.ipa` from the same link and install it the same
way. Your Tidy data is kept.

## Part 3: The 7-day refresh

A free Apple ID signs apps for **7 days**. Before that runs out:

1. Open **LocalDevVPN** → **Connect**.
2. Open **SideStore** → **My Apps** → tap the days counter (or **Refresh All**).

Tidy's Home screen shows "Signature renews in N days" and turns red with a reminder when less than
2 days are left. If you miss it, Tidy just won't open until you refresh. Nothing is lost: refresh
in SideStore and it opens again.

**Free Apple ID limits:** up to 3 sideloaded apps at once (SideStore counts as one), and up to 10
new app IDs per week.

## Troubleshooting

- **Refresh fails / "pairing file" errors:** the pairing file can expire after an iOS update or
  reset. Plug into the PC, open iloader, and follow SideStore's *pairing file* guide to replace it.
- **"Untrusted Developer" when opening an app:** repeat Part 1 step 6.
- **Nothing installs or refreshes:** make sure LocalDevVPN is connected and you're on Wi-Fi.
- **iloader problems:** SideStore's docs point to the *idevice* Discord for iloader issues.
