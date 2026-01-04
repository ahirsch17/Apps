import React from "react";
import { ImageBackground, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import TopBar from "../components/TopBar";
import { UI } from "../constants/assets";
import { useGameStore } from "../store/gameStore";

export default function PrestigeScreen() {
  const insets = useSafeAreaInsets();

  const goodwill = useGameStore((s) => s.goodwill);
  const renovationPoints = useGameStore((s) => s.renovationPoints);
  const spirit = useGameStore((s) => s.spirit);
  const resetAll = useGameStore((s) => s.resetAll);

  return (
    <View style={styles.root}>
      <TopBar goodwill={goodwill} renovationPoints={renovationPoints} spirit={spirit} />
      <ImageBackground source={UI.prestigeMonument} style={styles.bg} resizeMode="cover">
        <View style={[styles.content, { paddingBottom: Math.max(18, insets.bottom + 10) }]}>
          <Text style={styles.h1}>Community Revival</Text>
          <Text style={styles.sub}>
            This is where prestige will live. For now, you can reset your save to quickly test progression.
          </Text>

          <TouchableOpacity style={styles.dangerBtn} onPress={resetAll} accessibilityRole="button">
            <Text style={styles.dangerText}>Reset Save</Text>
          </TouchableOpacity>
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
  dangerBtn: {
    marginTop: 12,
    alignSelf: "flex-start",
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: "#3b0a0a",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#ef4444",
  },
  dangerText: { color: "white", fontWeight: "900" },
});


