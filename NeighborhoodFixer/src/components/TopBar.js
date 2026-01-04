import React from "react";
import { Image, StyleSheet, Text, View } from "react-native";

import { ICONS } from "../constants/assets";
import { formatNumber } from "../utils/format";

export default function TopBar({ goodwill, renovationPoints, spirit }) {
  return (
    <View style={styles.bar}>
      <View style={styles.pill}>
        <Image source={ICONS.heart} style={styles.icon} />
        <Text style={styles.text}>{formatNumber(goodwill)}</Text>
      </View>
      <View style={styles.pill}>
        <Image source={ICONS.hammer} style={styles.icon} />
        <Text style={styles.text}>{formatNumber(renovationPoints)}</Text>
      </View>
      <View style={styles.pill}>
        <Image source={ICONS.spirit} style={styles.icon} />
        <Text style={styles.text}>{formatNumber(spirit)}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: "rgba(11,16,32,0.9)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "#1f2a44",
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: "#121a33",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#2b3a63",
  },
  icon: { width: 18, height: 18, resizeMode: "contain" },
  text: { color: "white", fontWeight: "700" },
});


