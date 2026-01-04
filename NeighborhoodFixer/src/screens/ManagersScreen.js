import React from "react";
import { Image, ImageBackground, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import TopBar from "../components/TopBar";
import { MANAGERS, UI } from "../constants/assets";
import { MANAGER_DEFS } from "../constants/gameData";
import { useGameStore } from "../store/gameStore";

export default function ManagersScreen() {
  const insets = useSafeAreaInsets();

  const goodwill = useGameStore((s) => s.goodwill);
  const renovationPoints = useGameStore((s) => s.renovationPoints);
  const spirit = useGameStore((s) => s.spirit);

  return (
    <View style={styles.root}>
      <TopBar goodwill={goodwill} renovationPoints={renovationPoints} spirit={spirit} />
      <ImageBackground source={UI.managerDesk} style={styles.bg} resizeMode="cover">
        <View style={[styles.content, { paddingBottom: Math.max(18, insets.bottom + 10) }]}>
          <Text style={styles.h1}>Managers</Text>
          <Text style={styles.sub}>
            Coming next: hire managers to automate specific properties. (This screen is wired and ready.)
          </Text>

          <View style={styles.grid}>
            {MANAGER_DEFS.map((m) => (
              <View key={m.id} style={styles.card}>
                <Image source={MANAGERS[m.id]} style={styles.avatar} />
                <Text style={styles.name}>{m.name}</Text>
                <Text style={styles.meta}>Tier {m.tier}</Text>
                <Text style={styles.meta}>{m.bonus}</Text>
              </View>
            ))}
          </View>
        </View>
      </ImageBackground>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#0b1020" },
  bg: { flex: 1 },
  content: { flex: 1, paddingHorizontal: 16, paddingTop: 18, gap: 10 },
  h1: { color: "white", fontSize: 26, fontWeight: "900" },
  sub: { color: "#c7d2fe", lineHeight: 20 },
  grid: { flexDirection: "row", flexWrap: "wrap", gap: 10, marginTop: 8 },
  card: {
    width: "48%",
    padding: 10,
    borderRadius: 14,
    backgroundColor: "rgba(11,16,32,0.92)",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#2b3a63",
  },
  avatar: { width: "100%", height: 110, borderRadius: 12, resizeMode: "cover" },
  name: { color: "white", fontWeight: "900", marginTop: 8 },
  meta: { color: "#c7d2fe", fontSize: 12, marginTop: 2 },
});


