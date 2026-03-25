import { useState, useEffect } from 'react';
import SimCardsManager from 'react-native-sim-cards-manager';
import { INDIAN_CARRIERS } from '../api/carrierCodes';

export const useCarrier = () => {
    const [sims, setSims] = useState([]);
    const [activeCarrier, setActiveCarrier] = useState(INDIAN_CARRIERS.JIO); // Default

    const refreshSimData = async () => {
        try {
            const simCards = await SimCardsManager.getSimCardsNative();
            setSims(simCards);

            // Auto-detect based on SIM 1 (Primary)
            if (simCards.length > 0) {
                const mnc = simCards[0].mccmnc;
                const detected = Object.values(INDIAN_CARRIERS).find(c => c.mccmnc.includes(mnc));
                if (detected) setActiveCarrier(detected);
            }
        } catch (error) {
            console.log("SIM Detection Error:", error);
        }
    };

    useEffect(() => {
        refreshSimData();
    }, []);

    return { sims, activeCarrier, setActiveCarrier, refreshSimData };
};