import React from "react";
import { FlatList, Image, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import TopBar from "../components/TopBar";
import { PROPERTIES } from "../constants/assets";
import { PROPERTY_DEFS, upgradeCost } from "../constants/gameData";
import { useGameStore } from "../store/gameStore";
import { formatNumber } from "../utils/format";

function PropertyCard({ def, level, canAfford, cost, onUpgrade }) {
  return (
    <View style={styles.card}>
      <Image source={PROPERTIES[def.id]} style={styles.cardImg} />
      <View style={{ flex: 1 }}>
        <Text style={styles.cardTitle}>{def.name}</Text>
        <Text style={styles.cardMeta}>
          Tier {def.tier} • Level {level}
        </Text>
        <Text style={styles.cardMeta}>Upgrade cost: {formatNumber(cost)} goodwill</Text>
      </View>
      <TouchableOpacity
        onPress={onUpgrade}
        disabled={!canAfford}
        style={[styles.buyBtn, !canAfford && styles.buyBtnDisabled]}
        accessibilityRole="button"
        accessibilityLabel={`Upgrade ${def.name}`}
      >
        <Text style={styles.buyBtnText}>{canAfford ? "Upgrade" : "Need\nmore"}</Text>
      </TouchableOpacity>
    </View>
  );
}

export default function UpgradesScreen() {
  const insets = useSafeAreaInsets();

  const goodwill = useGameStore((s) => s.goodwill);
  const renovationPoints = useGameStore((s) => s.renovationPoints);
  const spirit = useGameStore((s) => s.spirit);
  const properties = useGameStore((s) => s.properties);
  const upgradeProperty = useGameStore((s) => s.upgradeProperty);
  const load = useGameStore((s) => s.load);

  React.useEffect(() => {
    load();
  }, [load]);

  const levelById = React.useMemo(() => {
    const map = {};
    for (const p of properties) map[p.id] = p.level ?? 0;
    return map;
  }, [properties]);

  return (
    <View style={styles.root}>
      <TopBar goodwill={goodwill} renovationPoints={renovationPoints} spirit={spirit} />
      <FlatList
        contentContainerStyle={{ paddingBottom: Math.max(18, insets.bottom + 10) }}
        style={styles.list}
        data={PROPERTY_DEFS}
        keyExtractor={(d) => d.id}
        renderItem={({ item }) => {
          const level = levelById[item.id] ?? 0;
          const cost = upgradeCost(item.baseCost, level);
          const canAfford = goodwill >= cost;
          return (
            <PropertyCard
              def={item}
              level={level}
              cost={cost}
              canAfford={canAfford}
              onUpgrade={() => upgradeProperty(item.id)}
            />
          );
        }}
        ListHeaderComponent={
          <View style={styles.header}>
            <Text style={styles.h1}>Upgrades</Text>
            <Text style={styles.sub}>Level properties to increase passive income.</Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#0b1020" },
  list: { flex: 1, paddingHorizontal: 14 },
  header: { paddingTop: 16, paddingBottom: 10, gap: 6 },
  h1: { color: "white", fontSize: 26, fontWeight: "900" },
  sub: { color: "#c7d2fe" },
  card: {
    flexDirection: "row",
    gap: 12,
    padding: 12,
    borderRadius: 16,
    backgroundColor: "#121a33",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#2b3a63",
    marginBottom: 10,
    alignItems: "center",
  },
  cardImg: { width: 56, height: 56, borderRadius: 12, resizeMode: "cover" },
  cardTitle: { color: "white", fontWeight: "900", fontSize: 16 },
  cardMeta: { color: "#c7d2fe", marginTop: 2, fontSize: 12 },
  buyBtn: {
    width: 78,
    height: 56,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#2b3a63",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#4b63a6",
  },
  buyBtnDisabled: { opacity: 0.55 },
  buyBtnText: { color: "white", fontWeight: "900", textAlign: "center", fontSize: 12 },
});


