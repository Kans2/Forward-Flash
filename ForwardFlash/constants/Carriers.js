export const CARRIERS = {
    JIO: {
        name: 'Jio',
        activate: '*401*', // Format: *401*[number]
        deactivate: '*402',
        status: '*409',
    },
    AIRTEL: {
        name: 'Airtel',
        activate: '**21*', // Format: **21*[number]#
        deactivate: '##21#',
        status: '*#21#',
        suffix: '#',
    },
    VI: {
        name: 'Vi',
        activate: '**21*',
        deactivate: '##21#',
        status: '*#21#',
        suffix: '#',
    },
};