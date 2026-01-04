import React from "react";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";

import GameScreen from "../screens/GameScreen";
import UpgradesScreen from "../screens/UpgradesScreen";
import ManagersScreen from "../screens/ManagersScreen";
import AchievementsScreen from "../screens/AchievementsScreen";
import PrestigeScreen from "../screens/PrestigeScreen";

const Tab = createBottomTabNavigator();

export default function RootNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: { backgroundColor: "#0b1020", borderTopColor: "#1f2a44" },
        tabBarActiveTintColor: "#c7d2fe",
        tabBarInactiveTintColor: "#6b7280",
      }}
    >
      <Tab.Screen name="Neighborhood" component={GameScreen} />
      <Tab.Screen name="Upgrades" component={UpgradesScreen} />
      <Tab.Screen name="Managers" component={ManagersScreen} />
      <Tab.Screen name="Achievements" component={AchievementsScreen} />
      <Tab.Screen name="Prestige" component={PrestigeScreen} />
    </Tab.Navigator>
  );
}


