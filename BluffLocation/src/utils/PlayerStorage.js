import AsyncStorage from '@react-native-async-storage/async-storage';

const PLAYER_NAME_KEY = '@BluffLocation:playerName';

export async function getPlayerName() {
  try {
    const name = await AsyncStorage.getItem(PLAYER_NAME_KEY);
    return name || '';
  } catch (error) {
    console.error('Error getting player name:', error);
    return '';
  }
}

export async function savePlayerName(name) {
  try {
    await AsyncStorage.setItem(PLAYER_NAME_KEY, name);
  } catch (error) {
    console.error('Error saving player name:', error);
  }
}




