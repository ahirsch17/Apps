import AsyncStorage from "@react-native-async-storage/async-storage";
import { create } from "zustand";

import { PROPERTY_DEFS, propertyIncomePerSecond, upgradeCost } from "../constants/gameData";

const STORAGE_KEY = "neighborhoodfixer:v1";

function buildInitialProperties() {
  return PROPERTY_DEFS.map((p) => ({
    id: p.id,
    level: 0,
  }));
}

function computeIncomePerSecond(propertiesById) {
  let total = 0;
  for (const def of PROPERTY_DEFS) {
    const level = propertiesById[def.id]?.level ?? 0;
    total += propertyIncomePerSecond(def.baseIncome, level);
  }
  return total;
}

export const useGameStore = create((set, get) => ({
  // Currencies
  goodwill: 0,
  renovationPoints: 0,
  spirit: 0,

  // Properties
  properties: buildInitialProperties(),

  // Runtime
  lastTickMs: Date.now(),

  // Derived
  getPropertiesById: () => {
    const byId = {};
    for (const p of get().properties) byId[p.id] = p;
    return byId;
  },
  getIncomePerSecond: () => computeIncomePerSecond(get().getPropertiesById()),

  // Actions
  tapRenovate: () => set((s) => ({ goodwill: s.goodwill + 1 })),

  upgradeProperty: (propertyId) => {
    const state = get();
    const def = PROPERTY_DEFS.find((p) => p.id === propertyId);
    if (!def) return;

    const current = state.properties.find((p) => p.id === propertyId);
    const level = current?.level ?? 0;
    const cost = upgradeCost(def.baseCost, level);

    if (state.goodwill < cost) return;

    set((s) => ({
      goodwill: s.goodwill - cost,
      properties: s.properties.map((p) =>
        p.id === propertyId ? { ...p, level: (p.level ?? 0) + 1 } : p
      ),
    }));
  },

  tick: () => {
    const now = Date.now();
    const { lastTickMs } = get();
    const dtSeconds = Math.max(0, (now - lastTickMs) / 1000);
    if (dtSeconds <= 0) return;

    const incomePerSecond = get().getIncomePerSecond();
    const earned = incomePerSecond * dtSeconds;

    set((s) => ({
      goodwill: s.goodwill + earned,
      lastTickMs: now,
    }));
  },

  // Persistence
  load: async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (!raw) return;
      const parsed = JSON.parse(raw);

      set((s) => ({
        goodwill: typeof parsed.goodwill === "number" ? parsed.goodwill : s.goodwill,
        renovationPoints:
          typeof parsed.renovationPoints === "number" ? parsed.renovationPoints : s.renovationPoints,
        spirit: typeof parsed.spirit === "number" ? parsed.spirit : s.spirit,
        properties: Array.isArray(parsed.properties) ? parsed.properties : s.properties,
        lastTickMs: Date.now(),
      }));
    } catch {
      // ignore corrupt save
    }
  },

  save: async () => {
    const s = get();
    const payload = JSON.stringify({
      goodwill: s.goodwill,
      renovationPoints: s.renovationPoints,
      spirit: s.spirit,
      properties: s.properties,
    });
    try {
      await AsyncStorage.setItem(STORAGE_KEY, payload);
    } catch {
      // ignore save failures
    }
  },

  resetAll: async () => {
    set({
      goodwill: 0,
      renovationPoints: 0,
      spirit: 0,
      properties: buildInitialProperties(),
      lastTickMs: Date.now(),
    });
    try {
      await AsyncStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
  },
}));


