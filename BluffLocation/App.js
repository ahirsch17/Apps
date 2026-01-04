import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { StatusBar } from 'expo-status-bar';
import MainMenuView from './src/views/MainMenuView';
import CreateGameView from './src/views/CreateGameView';
import JoinGameView from './src/views/JoinGameView';
import GameRoomView from './src/views/GameRoomView';
import RulesView from './src/views/RulesView';

const Stack = createStackNavigator();

export default function App() {
  return (
    <>
      <StatusBar style="auto" />
      <NavigationContainer>
        <Stack.Navigator initialRouteName="MainMenu" screenOptions={{ headerShown: false }}>
          <Stack.Screen name="MainMenu" component={MainMenuView} />
          <Stack.Screen name="CreateGame" component={CreateGameView} />
          <Stack.Screen name="JoinGame" component={JoinGameView} />
          <Stack.Screen name="GameRoom" component={GameRoomView} />
          <Stack.Screen name="Rules" component={RulesView} />
        </Stack.Navigator>
      </NavigationContainer>
    </>
  );
}

