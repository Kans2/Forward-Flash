import React, { useState, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  StyleSheet, SafeAreaView, StatusBar, ScrollView
} from 'react-native';
import {
  PhoneForwarded,
  Settings,
  Zap,
  CheckCircle2,
  CircleOff
} from 'lucide-react-native';

// Import our new structure
import { useCarrier } from './src/hooks/useCarrier';
import { useAppStore } from './src/store/useAppStore';
import { triggerForwarding } from './utils/forwarder';

export default function App() {
  const { activeCarrier, sims } = useCarrier();
  const { isForwardingActive, savedNumber, setForwardingStatus } = useAppStore();
  const [inputNumber, setInputNumber] = useState(savedNumber || '');

  const handleToggle = async () => {
    if (isForwardingActive) {
      // Deactivate
      await triggerForwarding(activeCarrier, '', false);
      setForwardingStatus(false);
    } else {
      // Activate
      if (inputNumber.length < 10) return;
      await triggerForwarding(activeCarrier, inputNumber, true);
      setForwardingStatus(true, inputNumber);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <ScrollView contentContainerStyle={styles.scrollContent}>

        {/* Header Section */}
        <View style={styles.header}>
          <Text style={styles.brand}>ForwardFlash</Text>
          <TouchableOpacity style={styles.iconBtn}>
            <Settings color="#64748b" size={24} />
          </TouchableOpacity>
        </View>

        {/* Smart Detection Card */}
        <View style={styles.statusCard}>
          <View style={styles.carrierInfo}>
            <View style={[styles.indicator, { backgroundColor: isForwardingActive ? '#10b981' : '#cbd5e1' }]} />
            <Text style={styles.carrierText}>
              Active SIM: <Text style={{ fontWeight: '700' }}>{activeCarrier.name}</Text>
            </Text>
          </View>
          <Text style={styles.statusMain}>
            {isForwardingActive ? "Forwarding is ON" : "Forwarding is OFF"}
          </Text>
        </View>

        {/* Action Section */}
        <View style={styles.actionBox}>
          <Text style={styles.label}>Forwarding Number</Text>
          <TextInput
            style={styles.input}
            placeholder="98XXXXXX00"
            keyboardType="phone-pad"
            value={inputNumber}
            onChangeText={setInputNumber}
            editable={!isForwardingActive}
          />

          <TouchableOpacity
            onPress={handleToggle}
            style={[styles.mainBtn, isForwardingActive ? styles.btnStop : styles.btnStart]}
          >
            {isForwardingActive ? (
              <CircleOff color="white" size={22} />
            ) : (
              <PhoneForwarded color="white" size={22} />
            )}
            <Text style={styles.btnText}>
              {isForwardingActive ? "Stop Forwarding" : "Start Forwarding"}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Presets - The "Google" touch */}
        <Text style={styles.sectionTitle}>Quick Presets</Text>
        <View style={styles.presetGrid}>
          <PresetItem
            icon={<Zap size={20} color="#f59e0b" />}
            title="Office"
            num="011-XXXXXXX"
            onPress={() => setInputNumber('0112345678')}
          />
          <PresetItem
            icon={<CheckCircle2 size={20} color="#3b82f6" />}
            title="Mom"
            num="99XXXXXXXX"
            onPress={() => setInputNumber('9988776655')}
          />
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}

// Sub-component for clean code
const PresetItem = ({ icon, title, num, onPress }) => (
  <TouchableOpacity style={styles.presetCard} onPress={onPress}>
    {icon}
    <Text style={styles.presetTitle}>{title}</Text>
    <Text style={styles.presetNum}>{num}</Text>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8fafc' },
  scrollContent: { padding: 24 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 30 },
  brand: { fontSize: 24, fontWeight: '800', color: '#0f172a', letterSpacing: -0.5 },
  iconBtn: { padding: 8, backgroundColor: '#f1f5f9', borderRadius: 12 },
  statusCard: { backgroundColor: 'white', padding: 20, borderRadius: 24, elevation: 2, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 10 },
  carrierInfo: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  indicator: { width: 8, height: 8, borderRadius: 4, marginRight: 8 },
  carrierText: { fontSize: 14, color: '#64748b' },
  statusMain: { fontSize: 26, fontWeight: '800', color: '#1e293b' },
  actionBox: { marginTop: 30, backgroundColor: 'white', padding: 24, borderRadius: 24 },
  label: { fontSize: 12, fontWeight: '700', color: '#94a3b8', textTransform: 'uppercase', marginBottom: 8 },
  input: { fontSize: 24, fontWeight: '600', color: '#1e293b', borderBottomWidth: 2, borderBottomColor: '#f1f5f9', paddingVertical: 12, marginBottom: 24 },
  mainBtn: { flexDirection: 'row', padding: 18, borderRadius: 16, justifyContent: 'center', alignItems: 'center', gap: 12 },
  btnStart: { backgroundColor: '#3b82f6' },
  btnStop: { backgroundColor: '#ef4444' },
  btnText: { color: 'white', fontSize: 16, fontWeight: '700' },
  sectionTitle: { marginTop: 40, marginBottom: 16, fontSize: 18, fontWeight: '700', color: '#334155' },
  presetGrid: { flexDirection: 'row', gap: 12 },
  presetCard: { flex: 1, backgroundColor: 'white', padding: 16, borderRadius: 20, borderWidth: 1, borderColor: '#f1f5f9' },
  presetTitle: { fontSize: 15, fontWeight: '700', color: '#1e293b', marginTop: 8 },
  presetNum: { fontSize: 12, color: '#94a3b8', marginTop: 2 }
});