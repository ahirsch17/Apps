import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, Alert, ImageBackground, Platform } from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { useNavigation } from '@react-navigation/native';
import { getPlayerName, savePlayerName } from '../utils/PlayerStorage';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import GameManager from '../managers/GameManager';

export default function CreateGameView() {
  const navigation = useNavigation();
  const [timerDuration, setTimerDuration] = useState(5);
  const [playerName, setPlayerName] = useState('');
  const [needsNameEntry, setNeedsNameEntry] = useState(false);

  const timerOptions = [3, 4, 5, 6, 7, 8, 9, 10, 12, 15];

  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });

  useEffect(() => {
    checkPlayerName();
    setupWebSocketListeners();
    return () => {
      cleanupWebSocketListeners();
    };
  }, []);

  const cleanupWebSocketListeners = () => {
    GameManager.off('room_created');
    GameManager.off('error');
  };

  const setupWebSocketListeners = () => {
    // Listen for room_created event - server will send game code
    // Navigate immediately to GameRoom - no intermediate screen
    const roomCreatedHandler = (data) => {
      GameManager.off('room_created', roomCreatedHandler);
      if (data?.room && data?.time_limit_minutes) {
        GameManager.updateLocalTimer(data.room, data.time_limit_minutes);
      }
      // Navigate directly to game room with server-provided code (use replace to prevent going back)
      navigation.replace('GameRoom', {
        gameCode: data.room,
        timerDuration: data.time_limit_minutes,
        isHost: true,
        playerName: playerName,
      });
    };
    GameManager.on('room_created', roomCreatedHandler);

    // Listen for errors
    GameManager.on('error', (data) => {
      Alert.alert('Error', data.message || 'Failed to create game');
    });
  };

  const checkPlayerName = async () => {
    const savedName = await getPlayerName();
    if (!savedName || savedName.trim().length === 0) {
      setNeedsNameEntry(true);
    } else {
      setPlayerName(savedName);
    }
  };

  const handleNameSubmit = async () => {
    const trimmedName = playerName.trim();
    if (trimmedName.length === 0) {
      Alert.alert('Error', 'Please enter your name');
      return;
    }
    await savePlayerName(trimmedName);
    setNeedsNameEntry(false);
  };

  const createGame = () => {
    // Websocket details live in `Apps/client.js` via GameManager.
    // The room code will come from server via 'room_created' event.
    GameManager.createGame(playerName, timerDuration);
  };

  if (!cinzelLoaded || !poppinsLoaded) {
    return null; // Or a loading indicator
  }

  if (needsNameEntry) {
    return (
      <ImageBackground
        source={require('../../assets/background.png')}
        style={styles.container}
        resizeMode="cover"
      >
        <View style={styles.overlay}>
          <View style={styles.content}>
            <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>Enter Your Name</Text>

            <TextInput
              style={styles.nameInput}
              value={playerName}
              onChangeText={setPlayerName}
              placeholder="Your Name"
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              autoCapitalize="words"
              autoCorrect={false}
              autoFocus={true}
            />

            <TouchableOpacity
              style={[styles.button, playerName.trim().length === 0 && styles.buttonDisabled]}
              onPress={handleNameSubmit}
              disabled={playerName.trim().length === 0}
            >
              <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                Continue
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </ImageBackground>
    );
  }

  return (
    <ImageBackground
      source={require('../../assets/background.png')}
      style={styles.container}
      resizeMode="cover"
    >
      <View style={styles.overlay}>
        <View style={styles.content}>
          <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>
            Create Game
          </Text>

          <Text style={styles.label}>Timer Duration</Text>

          <View style={styles.pickerWrapper}>
            <Picker
              selectedValue={timerDuration}
              onValueChange={(itemValue) => setTimerDuration(itemValue)}
              style={styles.picker}
              itemStyle={styles.pickerItem}
              dropdownIconColor="#FFFFFF"
            >
              {timerOptions.map((minutes) => (
                <Picker.Item key={minutes} label={`${minutes} minutes`} value={minutes} />
              ))}
            </Picker>
          </View>

          <TouchableOpacity style={styles.createButton} onPress={createGame}>
            <Text style={[styles.createButtonText, { fontFamily: 'Poppins_600SemiBold' }]}>Create Game</Text>
          </TouchableOpacity>
        </View>
      </View>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    height: '100%',
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  content: {
    justifyContent: 'center',
    alignItems: 'center',
    width: '100%',
    maxWidth: 400,
  },
  title: {
    fontSize: 36,
    fontWeight: 'bold',
    marginBottom: 30,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  label: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 15,
    color: '#E0E0E0',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  pickerWrapper: {
    width: '100%',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    borderWidth: 2,
    borderColor: 'rgba(139, 0, 0, 0.5)',
    marginBottom: 30,
    overflow: 'hidden',
  },
  picker: {
    width: '100%',
    height: Platform.OS === 'ios' ? 180 : 50,
    color: '#FFFFFF',
  },
  pickerItem: {
    color: '#FFFFFF',
    fontSize: 20,
    height: 180,
  },
  createButton: {
    backgroundColor: '#D4A574',
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 12,
    marginTop: 20,
    width: '100%',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
  createButtonText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  nameInput: {
    fontSize: 24,
    textAlign: 'center',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 12,
    padding: 15,
    width: '100%',
    marginBottom: 30,
    color: '#FFFFFF',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  button: {
    backgroundColor: '#D4A574',
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 12,
    width: '100%',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
  buttonDisabled: {
    backgroundColor: 'rgba(150, 150, 150, 0.5)',
    borderColor: 'rgba(200, 200, 200, 0.3)',
  },
  buttonText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
});
