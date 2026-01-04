import React from "react";
import { Image, ImageBackground, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import TopBar from "../components/TopBar";
import { ICONS, UI } from "../constants/assets";
import { useGameStore } from "../store/gameStore";
import { formatNumber } from "../utils/format";

export default function GameScreen() {
  const insets = useSafeAreaInsets();

  const goodwill = useGameStore((s) => s.goodwill);
  const renovationPoints = useGameStore((s) => s.renovationPoints);
  const spirit = useGameStore((s) => s.spirit);
  const tapRenovate = useGameStore((s) => s.tapRenovate);
  const incomePerSecond = useGameStore((s) => s.getIncomePerSecond());
  const tick = useGameStore((s) => s.tick);
  const load = useGameStore((s) => s.load);
  const save = useGameStore((s) => s.save);

  React.useEffect(() => {
    load();
  }, [load]);

  React.useEffect(() => {
    const id = setInterval(() => tick(), 1000);
    return () => clearInterval(id);
  }, [tick]);

  React.useEffect(() => {
    const id = setInterval(() => save(), 5000);
    return () => clearInterval(id);
  }, [save]);

  return (
    <View style={styles.root}>
      <TopBar goodwill={goodwill} renovationPoints={renovationPoints} spirit={spirit} />
      <ImageBackground source={UI.background} style={styles.bg} resizeMode="cover">
        <View style={[styles.content, { paddingBottom: Math.max(18, insets.bottom + 10) }]}>
          <Text style={styles.h1}>Neighborhood</Text>
          <Text style={styles.sub}>
            Passive: <Text style={styles.mono}>{formatNumber(incomePerSecond)}</Text> goodwill/sec
          </Text>

          <TouchableOpacity
            style={styles.bigButton}
            onPress={tapRenovate}
            activeOpacity={0.85}
            accessibilityRole="button"
            accessibilityLabel="Tap to renovate"
          >
            <View style={styles.bigButtonInner}>
              <Image source={ICONS.hammer} style={styles.bigIcon} />
              <View style={{ flex: 1 }}>
                <Text style={styles.bigTitle}>Tap to Renovate</Text>
                <Text style={styles.bigSubtitle}>+1 Goodwill</Text>
              </View>
              <Image source={ICONS.heart} style={styles.bigIcon} />
            </View>
          </TouchableOpacity>

          <Text style={styles.tip}>
            Go to <Text style={styles.tipEm}>Upgrades</Text> to level up properties and increase your passive income.
          </Text>
        </View>
      </ImageBackground>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#0b1020" },
  bg: { flex: 1 },
  content: { flex: 1, paddingHorizontal: 16, paddingTop: 18, gap: 12 },
  h1: { color: "white", fontSize: 28, fontWeight: "900" },
  sub: { color: "#c7d2fe" },
  mono: { fontVariant: ["tabular-nums"], fontWeight: "800" },
  bigButton: {
    marginTop: 12,
    borderRadius: 18,
    backgroundColor: "rgba(11,16,32,0.92)",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#2b3a63",
    overflow: "hidden",
  },
  bigButtonInner: { flexDirection: "row", alignItems: "center", gap: 12, padding: 16 },
  bigIcon: { width: 34, height: 34, resizeMode: "contain" },
  bigTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  bigSubtitle: { color: "#c7d2fe", marginTop: 2 },
  tip: { color: "#e5e7eb", marginTop: 8, lineHeight: 20 },
  tipEm: { color: "#c7d2fe", fontWeight: "800" },
});


