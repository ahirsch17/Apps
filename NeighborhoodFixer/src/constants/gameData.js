export const PROPERTY_DEFS = [
  // Tier 1
  { id: "MowLawns", name: "Mow Lawns", tier: 1, baseCost: 10, baseIncome: 0.2 },
  { id: "PlantFlowers", name: "Plant Flowers", tier: 1, baseCost: 30, baseIncome: 0.6 },
  { id: "CommunityGarden", name: "Community Garden", tier: 1, baseCost: 80, baseIncome: 1.5 },

  // Tier 2
  { id: "FixPorches", name: "Fix Porches", tier: 2, baseCost: 250, baseIncome: 4 },
  { id: "RepaintHouses", name: "Repaint Houses", tier: 2, baseCost: 650, baseIncome: 9 },
  { id: "RenovateBuildings", name: "Renovate Buildings", tier: 2, baseCost: 1400, baseIncome: 18 },

  // Tier 3
  { id: "OpenShops", name: "Open Shops", tier: 3, baseCost: 4000, baseIncome: 45 },
  { id: "BuildParks", name: "Build Parks", tier: 3, baseCost: 9000, baseIncome: 90 },
  { id: "CreatePlaza", name: "Create Plaza", tier: 3, baseCost: 18000, baseIncome: 160 },

  // Tier 4
  { id: "AttractBusinesses", name: "Attract Businesses", tier: 4, baseCost: 45000, baseIncome: 350 },
  { id: "BuildApartments", name: "Build Apartments", tier: 4, baseCost: 90000, baseIncome: 700 },
  { id: "DowntownDistrict", name: "Downtown District", tier: 4, baseCost: 160000, baseIncome: 1200 },

  // Tier 5
  { id: "Stadiums", name: "Stadiums", tier: 5, baseCost: 350000, baseIncome: 2600 },
  { id: "Skyscrapers", name: "Skyscrapers", tier: 5, baseCost: 750000, baseIncome: 5600 },
  { id: "SmartCity", name: "Smart City", tier: 5, baseCost: 1500000, baseIncome: 11000 },
];

export const MANAGER_DEFS = [
  { id: "BuilderBobbi", name: "Bobbi the Builder", tier: 1, cost: 25, bonus: "Tier 1 speed" },
  { id: "GrumpyGus", name: "Grumpy Gus", tier: 2, cost: 120, bonus: "Tier 2 output" },
  { id: "DesignerDana", name: "Designer Dana", tier: 3, cost: 450, bonus: "Cosmetic unlocks" },
  { id: "FixerFrank", name: "Fixer Frank", tier: 1, cost: 40, bonus: "Click bonuses" },
  { id: "PermitPatty", name: "Permit Patty", tier: 4, cost: 1200, bonus: "Unlock smoothing" },
  { id: "InvestorIvan", name: "Investor Ivan", tier: 5, cost: 3000, bonus: "Idle economy" },
];

export function upgradeCost(baseCost, level) {
  // level is current level; upgrading to level+1
  return Math.ceil(baseCost * Math.pow(1.15, level));
}

export function propertyIncomePerSecond(baseIncome, level) {
  // Simple curve for now; level 0 -> 0
  return level <= 0 ? 0 : baseIncome * level;
}


