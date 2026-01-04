import React, { useEffect, useRef, useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ImageBackground, Alert, Keyboard } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { getPlayerName, savePlayerName } from '../utils/PlayerStorage';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import GameManager from '../managers/GameManager';

export default function JoinGameView() {
  const navigation = useNavigation();
  const [gameCode, setGameCode] = useState('');
  const [playerName, setPlayerName] = useState('');
  const [hasCheckedName, setHasCheckedName] = useState(false);
  const [isJoining, setIsJoining] = useState(false);
  const isJoiningRef = useRef(false);

  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });

  useEffect(() => {
    (async () => {
      const savedName = await getPlayerName();
      if (savedName && savedName.trim().length > 0) setPlayerName(savedName);
      setHasCheckedName(true);
    })();

    return () => {
      GameManager.off('joined_room');
      GameManager.off('error');
    };
  }, []);

  const handleCodeChange = (text) => {
    const next = text.toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 6);
    setGameCode(next);
    if (next.length === 6) Keyboard.dismiss();
  };

  const joinGame = async () => {
    if (isJoiningRef.current) return;

    const trimmedName = playerName.trim();
    const trimmedCode = gameCode.trim().toLowerCase();

    if (trimmedName.length === 0 || trimmedCode.length !== 6) {
      Alert.alert('Error', 'Please enter name and valid 6-character code');
      return;
    }

    setIsJoining(true);
    isJoiningRef.current = true;

    await savePlayerName(trimmedName);

    GameManager.off('joined_room');
    GameManager.off('error');
    GameManager.off('room_created'); // defensive: clear any stale create listeners

    const joinedRoomHandler = (data) => {
      GameManager.off('joined_room', joinedRoomHandler);
      GameManager.off('error', errorHandler);
      setIsJoining(false);
      isJoiningRef.current = false;

      const room = data?.room || trimmedCode;
      const serverTimer = data?.time_limit_minutes || GameManager.getLocalTimer(room) || 5;
      navigation.replace('GameRoom', {
        gameCode: room,
        timerDuration: serverTimer,
        isHost: false,
        playerName: trimmedName,
      });
    };

    const errorHandler = (errorData) => {
      const msg = (errorData?.message || '').toLowerCase();
      if (msg.includes('already in room') || msg.includes('already joined')) {
        GameManager.off('joined_room', joinedRoomHandler);
        GameManager.off('error', errorHandler);
        setIsJoining(false);
        isJoiningRef.current = false;

        navigation.replace('GameRoom', {
          gameCode: trimmedCode,
          timerDuration: 5,
          isHost: false,
          playerName: trimmedName,
        });
        return;
      }

      Alert.alert('Error', errorData.message || 'Failed to join game');
      GameManager.off('joined_room', joinedRoomHandler);
      GameManager.off('error', errorHandler);
      setIsJoining(false);
      isJoiningRef.current = false;
    };

    const timeoutId = setTimeout(() => {
      GameManager.off('joined_room', wrappedJoinedHandler);
      GameManager.off('error', wrappedErrorHandler);
      if (isJoiningRef.current) {
        Alert.alert('Timeout', 'Server response timed out. Please try again.');
        setIsJoining(false);
        isJoiningRef.current = false;
      }
    }, 10000);

    const wrappedJoinedHandler = (data) => {
      clearTimeout(timeoutId);
      joinedRoomHandler(data);
    };

    const wrappedErrorHandler = (data) => {
      clearTimeout(timeoutId);
      errorHandler(data);
    };

    GameManager.on('joined_room', wrappedJoinedHandler);
    GameManager.on('error', wrappedErrorHandler);

    GameManager.joinGame(trimmedCode, trimmedName);
  };

  if (!hasCheckedName || !cinzelLoaded || !poppinsLoaded) return null;

  return (
    <ImageBackground
      source={require('../../assets/background.png')}
      style={styles.container}
      resizeMode="cover"
    >
      <View style={styles.overlay}>
        <View style={styles.content}>
          <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>
            Join Game
          </Text>

          <TextInput
            style={styles.codeInput}
            value={gameCode}
            onChangeText={handleCodeChange}
            placeholder="ENTER CODE"
            placeholderTextColor="rgba(255, 255, 255, 0.5)"
            maxLength={6}
            autoCapitalize="none"
            autoCorrect={false}
            editable={!isJoining}
          />

          <TextInput
            style={styles.nameInput}
            value={playerName}
            onChangeText={setPlayerName}
            placeholder="Enter your name"
            placeholderTextColor="rgba(255, 255, 255, 0.5)"
            autoCapitalize="words"
            autoCorrect={false}
            editable={!isJoining}
          />

          <TouchableOpacity
            style={[
              styles.button,
              (gameCode.length !== 6 || playerName.trim().length === 0 || isJoining) && styles.buttonDisabled,
            ]}
            onPress={joinGame}
            disabled={gameCode.length !== 6 || playerName.trim().length === 0 || isJoining}
          >
            <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
              {isJoining ? 'Joining...' : 'Join Game'}
            </Text>
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
    padding: 20,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 42,
    fontWeight: '700',
    marginBottom: 30,
    color: '#FFFFFF',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 8,
    letterSpacing: 1,
  },
  codeInput: {
    fontSize: 32,
    fontWeight: 'bold',
    fontFamily: 'monospace',
    textAlign: 'center',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 12,
    padding: 15,
    width: 250,
    marginBottom: 10,
    color: '#FFFFFF',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  nameInput: {
    fontSize: 24,
    textAlign: 'center',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 12,
    padding: 15,
    width: 250,
    marginBottom: 18,
    color: '#FFFFFF',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  button: {
    backgroundColor: '#4A9EBF',
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#4A9EBF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 8,
  },
  buttonDisabled: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  buttonText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
});

