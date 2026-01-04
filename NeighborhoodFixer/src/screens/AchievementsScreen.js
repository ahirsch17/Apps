import React from "react";
import { ImageBackground, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import TopBar from "../components/TopBar";
import { UI } from "../constants/assets";
import { useGameStore } from "../store/gameStore";

export default function AchievementsScreen() {
  const insets = useSafeAreaInsets();

  const goodwill = useGameStore((s) => s.goodwill);
  const renovationPoints = useGameStore((s) => s.renovationPoints);
  const spirit = useGameStore((s) => s.spirit);

  return (
    <View style={styles.root}>
      <TopBar goodwill={goodwill} renovationPoints={renovationPoints} spirit={spirit} />
      <ImageBackground source={UI.achievementWall} style={styles.bg} resizeMode="cover">
        <View style={[styles.content, { paddingBottom: Math.max(18, insets.bottom + 10) }]}>
          <Text style={styles.h1}>Achievements</Text>
          <Text style={styles.sub}>Next step: track milestones and show a trophy wall.</Text>
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
});


