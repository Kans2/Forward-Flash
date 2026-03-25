import { create } from 'zustand';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

export const useAppStore = create((set) => ({
    isForwardingActive: storage.getBoolean('isForwardingActive') || false,
    savedNumber: storage.getString('savedNumber') || '',

    setForwardingStatus: (status, number) => {
        storage.set('isForwardingActive', status);
        if (number) storage.set('savedNumber', number);
        set({ isForwardingActive: status, savedNumber: number || '' });
    },
}));