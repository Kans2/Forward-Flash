import { Linking, Alert, Platform } from 'react-native';

/**
 * Triggers the USSD code for Call Forwarding
 * @param {Object} carrier - The carrier object from our CARRIERS constant
 * @param {string} number - The 10-digit mobile number to forward to
 * @param {boolean} enable - True to enable, False to disable
 */
export const triggerForwarding = async (carrier, number, enable = true) => {
    try {
        let ussdCode = '';

        if (enable) {
            // Validation for India: Must be 10 digits
            if (!number || number.length < 10) {
                Alert.alert("Invalid Number", "Please enter a valid 10-digit mobile number.");
                return;
            }

            // Construction: 
            // Jio: *401*9876543210
            // Airtel/Vi: **21*9876543210#
            ussdCode = `${carrier.activate}${number}${carrier.suffix || ''}`;
        } else {
            // Deactivation:
            // Jio: *402
            // Airtel/Vi: ##21#
            ussdCode = `${carrier.deactivate}`;
        }

        // IMPORTANT: Dialers treat '#' as a special character. 
        // We must URL encode it so it's passed correctly to the phone system.
        const encodedUssd = ussdCode.replace(/#/g, encodeURIComponent('#'));
        const url = `tel:${encodedUssd}`;

        const supported = await Linking.canOpenURL(url);

        if (supported) {
            await Linking.openURL(url);
        } else {
            Alert.alert(
                "Feature Not Supported",
                "Your device does not allow opening the dialer automatically."
            );
        }
    } catch (error) {
        console.error("Forwarding Error:", error);
        Alert.alert("Error", "Could not trigger the call forwarding request.");
    }
};