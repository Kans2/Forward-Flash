# Forward-Flash

Forward-Flash is a robust Flutter application designed to automate and manage call forwarding seamlessly. It provides a clean, preset-driven UI allowing users to route their incoming calls to differents numbers automatically, using Android's native USSD and TelephonyManager APIs.

## Features
- **Preset Management:** Save multiple forwarding numbers (e.g., Office, Vacation) for one-tap activation.
- **Silent Automation:** Forward calls entirely in the background without launching the intrusive native dialer using Android 8.0+ `TelephonyManager`.
- **Dual SIM Support:** Select exactly which SIM slot should execute the forwarding command.
- **Live Carrier Status Messages:** Captures strings directly from the mobile network (like "Call forwarding registered") and displays them gracefully inside the Flutter UI.

---

## 🚀 How to Run & View the App (USB Debugging)

To test the raw USSD capabilities of this application, you **must use a physical Android device** with an active SIM card. Emulators cannot dial USSD codes or connect to cellular networks.

### 1. Enable Developer Options on your Phone
1. Go to **Settings** > **About phone** on your Android device.
2. Scroll to **Build number** and tap it `7 times` rapidly. You should see a toast message saying *"You are now a developer!"*.
3. Go back to the main **Settings** menu and find **System** > **Developer options**.

### 2. Enable USB Debugging
1. Inside **Developer options**, scroll down to the **Debugging** section.
2. Toggle **USB debugging** to `ON`.
3. Plug your phone into your PC using a USB cable. 
4. Check your phone screen; if a prompt asks *"Allow USB debugging?"* from your computer's RSA key fingerprint, check "Always allow from this computer" and tap **Allow**.

### 3. Run the App
1. Open a terminal (or the terminal in VS Code/Android Studio).
2. Navigate into the Flutter project directory:
   ```bash
   cd my_first_app
   ```
3. Ensure your device is connected and recognized by Flutter:
   ```bash
   flutter devices
   ```
   *(You should see your physical phone model listed, not just web or windows).*
4. Build and install the app to your phone:
   ```bash
   flutter run
   ```
5. Wait for the APK to compile. The app will automatically open on your phone screen! 

*(Note: The app will request Phone Call permissions on its first launch. These are absolutely required for the application to transmit the required USSD codes over the mobile network).*