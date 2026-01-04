import React from 'react';
import { Tabs } from 'expo-router';

export default function TabsLayout() {
  return (
    <Tabs 
      screenOptions={{ 
        headerShown: false,
        tabBarStyle: { display: 'none' },
      }}
    >
      <Tabs.Screen name="index" options={{ title: 'Encrypted' }} />
      <Tabs.Screen name="game" options={{ title: 'Game' }} />
      <Tabs.Screen name="results" options={{ title: 'Results' }} />
    </Tabs>
  );
}


