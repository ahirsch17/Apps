import React, { useState } from 'react';
import { router } from 'expo-router';
import {
  Alert,
  ImageBackground,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import { useGameStore } from '../lib/hooks/useGameState';
import type { GameSettings, Player, PlayerRole, TeamColor } from '../lib/types/game';

interface PlayerSetup {
  name: string;
  team: TeamColor;
  role: PlayerRole;
}

export default function GameSetupScreen() {
  const initializeNewGame = useGameStore((s) => s.actions.initializeNewGame);

  const [players, setPlayers] = useState<PlayerSetup[]>([
    { name: '', team: 'red', role: 'encoder' },
    { name: '', team: 'red', role: 'decoder' },
    { name: '', team: 'blue', role: 'encoder' },
    { name: '', team: 'blue', role: 'decoder' },
  ]);

  const [useTimer, setUseTimer] = useState(false);
  const [timerMinutes, setTimerMinutes] = useState(3);

  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });

  if (!cinzelLoaded || !poppinsLoaded) {
    return null;
  }

  const updatePlayer = (index: number, field: keyof PlayerSetup, value: string) => {
    const newPlayers = [...players];
    newPlayers[index] = { ...newPlayers[index], [field]: value };
    setPlayers(newPlayers);
  };

  const addPlayer = () => {
    if (players.length >= 8) {
      Alert.alert('Maximum Players', 'You can have up to 8 players.');
      return;
    }
    setPlayers([...players, { name: '', team: 'red', role: 'decoder' }]);
  };

  const removePlayer = (index: number) => {
    if (players.length <= 4) {
      Alert.alert('Minimum Players', 'You need at least 4 players (2 per team).');
      return;
    }
    setPlayers(players.filter((_, i) => i !== index));
  };

  const randomizeTeams = () => {
    if (players.some(p => !p.name.trim())) {
      Alert.alert('Enter Names First', 'Please enter all player names before randomizing teams.');
      return;
    }

    // Shuffle players and split into two teams
    const shuffled = [...players].sort(() => Math.random() - 0.5);
    const midPoint = Math.ceil(shuffled.length / 2);
    
    const updated = shuffled.map((player, index) => ({
      ...player,
      team: (index < midPoint ? 'red' : 'blue') as TeamColor,
    }));

    setPlayers(updated);
    Alert.alert('Teams Randomized!', 'Players have been randomly assigned to Red and Blue teams.');
  };

  const randomizeRoles = () => {
    if (players.some(p => !p.name.trim())) {
      Alert.alert('Enter Names First', 'Please enter all player names before randomizing roles.');
      return;
    }

    // Count players per team
    const redPlayers = players.filter(p => p.team === 'red');
    const bluePlayers = players.filter(p => p.team === 'blue');

    if (redPlayers.length === 0 || bluePlayers.length === 0) {
      Alert.alert('Balance Teams', 'Both teams need at least one player before randomizing roles.');
      return;
    }

    // Randomly assign one encoder per team, rest are decoders
    const redShuffled = [...redPlayers].sort(() => Math.random() - 0.5);
    const blueShuffled = [...bluePlayers].sort(() => Math.random() - 0.5);

    const updated = players.map(player => {
      if (player.team === 'red') {
        const isEncoder = redShuffled[0].name === player.name;
        return { ...player, role: (isEncoder ? 'encoder' : 'decoder') as PlayerRole };
      } else {
        const isEncoder = blueShuffled[0].name === player.name;
        return { ...player, role: (isEncoder ? 'encoder' : 'decoder') as PlayerRole };
      }
    });

    setPlayers(updated);
    Alert.alert('Roles Randomized!', 'One Encoder has been selected for each team.');
  };

  const startGame = () => {
    // Validate player count
    if (players.length < 4) {
      Alert.alert('Not Enough Players', 'You need at least 4 players to start (2 per team).');
      return;
    }

    if (players.length > 8) {
      Alert.alert('Too Many Players', 'Maximum 8 players allowed.');
      return;
    }

    // Validate that all players have names
    const emptyNames = players.filter((p) => !p.name.trim());
    if (emptyNames.length > 0) {
      Alert.alert('Missing Names', 'Please enter names for all players.');
      return;
    }

    // Check that each team has at least one encoder and one decoder
    const redPlayers = players.filter((p) => p.team === 'red');
    const bluePlayers = players.filter((p) => p.team === 'blue');
    const redEncoders = redPlayers.filter((p) => p.role === 'encoder');
    const redDecoders = redPlayers.filter((p) => p.role === 'decoder');
    const blueEncoders = bluePlayers.filter((p) => p.role === 'encoder');
    const blueDecoders = bluePlayers.filter((p) => p.role === 'decoder');

    if (redPlayers.length === 0 || bluePlayers.length === 0) {
      Alert.alert('Team Setup', 'Both teams need at least one player. Use "Random Teams" button to auto-balance.');
      return;
    }

    if (redEncoders.length === 0 || redDecoders.length === 0) {
      Alert.alert('Team Setup', 'Red team needs at least one Encoder and one Decoder.');
      return;
    }

    if (blueEncoders.length === 0 || blueDecoders.length === 0) {
      Alert.alert('Team Setup', 'Blue team needs at least one Encoder and one Decoder.');
      return;
    }

    // Warn if teams are very unbalanced
    const diff = Math.abs(redPlayers.length - bluePlayers.length);
    if (diff > 2) {
      Alert.alert(
        'Unbalanced Teams',
        `Teams are unbalanced (${redPlayers.length} vs ${bluePlayers.length}). Continue anyway?`,
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Continue', onPress: () => proceedToGame() }
        ]
      );
      return;
    }

    proceedToGame();
  };

  const proceedToGame = () => {
    const gamePlayers: Player[] = players.map((p, i) => ({
      id: `player_${i + 1}`,
      name: p.name.trim(),
      team: p.team,
      role: p.role,
      isHost: i === 0,
    }));

    const settings: GameSettings = {
      useTimer,
      encoderTimer: useTimer ? timerMinutes * 60 : 60,
      decoderTimer: useTimer ? timerMinutes * 60 : 60,
      teamAssignment: 'choose',
      roleAssignment: 'choose',
    };

    initializeNewGame(gamePlayers, settings);
    router.push('/game');
  };

  return (
    <ImageBackground
      source={require('../assets/OtherScreensBackground.png')}
      style={styles.container}
      resizeMode="cover"
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.overlay}>
          <View style={styles.content}>
            <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>Game Setup</Text>

            <Text style={styles.sectionTitle}>Players</Text>

            <View style={styles.randomizeRow}>
              <TouchableOpacity style={styles.randomizeButton} onPress={randomizeTeams}>
                <Text style={styles.randomizeButtonText}>🎲 Random Teams</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.randomizeButton} onPress={randomizeRoles}>
                <Text style={styles.randomizeButtonText}>🎲 Random Roles</Text>
              </TouchableOpacity>
            </View>

            {players.map((player, index) => (
              <View key={index} style={styles.playerCard}>
                <View style={styles.playerHeader}>
                  <Text style={styles.playerNumber}>Player {index + 1}</Text>
                  {players.length > 2 && (
                    <TouchableOpacity onPress={() => removePlayer(index)} style={styles.removeButton}>
                      <Text style={styles.removeButtonText}>Remove</Text>
                    </TouchableOpacity>
                  )}
                </View>

                <TextInput
                  style={styles.input}
                  value={player.name}
                  onChangeText={(text) => updatePlayer(index, 'name', text)}
                  placeholder="Player Name"
                  placeholderTextColor="rgba(255, 255, 255, 0.4)"
                  autoCapitalize="words"
                />

                <View style={styles.pickerRow}>
                  <View style={styles.pickerContainer}>
                    <Text style={styles.pickerLabel}>Team</Text>
                    <View style={styles.pickerWrapper}>
                      <Picker
                        selectedValue={player.team}
                        onValueChange={(value: TeamColor) => updatePlayer(index, 'team', value)}
                        style={styles.picker}
                        dropdownIconColor="#FFFFFF"
                      >
                        <Picker.Item label="Red" value="red" />
                        <Picker.Item label="Blue" value="blue" />
                      </Picker>
                    </View>
                  </View>

                  <View style={styles.pickerContainer}>
                    <Text style={styles.pickerLabel}>Role</Text>
                    <View style={styles.pickerWrapper}>
                      <Picker
                        selectedValue={player.role}
                        onValueChange={(value: PlayerRole) => updatePlayer(index, 'role', value)}
                        style={styles.picker}
                        dropdownIconColor="#FFFFFF"
                      >
                        <Picker.Item label="Encoder" value="encoder" />
                        <Picker.Item label="Decoder" value="decoder" />
                      </Picker>
                    </View>
                  </View>
                </View>
              </View>
            ))}

            {players.length < 8 && (
              <TouchableOpacity style={styles.addButton} onPress={addPlayer}>
                <Text style={[styles.addButtonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                  + Add Player
                </Text>
              </TouchableOpacity>
            )}

            <Text style={styles.sectionTitle}>Game Options</Text>

            <View style={styles.optionCard}>
              <View style={styles.timerRow}>
                <Text style={styles.optionLabel}>Use Timer</Text>
                <TouchableOpacity
                  style={[styles.toggleButton, useTimer && styles.toggleButtonActive]}
                  onPress={() => setUseTimer(!useTimer)}
                >
                  <Text style={styles.toggleButtonText}>{useTimer ? 'ON' : 'OFF'}</Text>
                </TouchableOpacity>
              </View>

              {useTimer && (
                <View style={styles.timerPickerContainer}>
                  <Text style={styles.pickerLabel}>Timer Duration</Text>
                  <View style={styles.pickerWrapper}>
                    <Picker
                      selectedValue={timerMinutes}
                      onValueChange={(value: number) => setTimerMinutes(value)}
                      style={styles.picker}
                      dropdownIconColor="#FFFFFF"
                    >
                      {[1, 2, 3, 4, 5, 7, 10, 15].map((min) => (
                        <Picker.Item key={min} label={`${min} minute${min > 1 ? 's' : ''}`} value={min} />
                      ))}
                    </Picker>
                  </View>
                </View>
              )}
            </View>

            <TouchableOpacity style={styles.startButton} onPress={startGame}>
              <Text style={[styles.startButtonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                Start Game
              </Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
              <Text style={styles.backButtonText}>Back</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    height: '100%',
  },
  scrollContent: {
    flexGrow: 1,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    padding: 20,
    paddingTop: 60,
  },
  content: {
    width: '100%',
    maxWidth: 500,
    alignSelf: 'center',
  },
  title: {
    fontSize: 42,
    fontWeight: 'bold',
    marginBottom: 30,
    color: '#FFFFFF',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 6,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#E0E0E0',
    marginTop: 20,
    marginBottom: 15,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  playerCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 15,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  playerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  playerNumber: {
    fontSize: 16,
    fontWeight: '700',
    color: '#E0E0E0',
  },
  removeButton: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    backgroundColor: 'rgba(220, 53, 69, 0.8)',
    borderRadius: 6,
  },
  removeButtonText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '600',
  },
  input: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#FFFFFF',
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  pickerRow: {
    flexDirection: 'row',
    gap: 10,
  },
  pickerContainer: {
    flex: 1,
  },
  pickerLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#E0E0E0',
    marginBottom: 6,
  },
  pickerWrapper: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    overflow: 'hidden',
  },
  picker: {
    color: '#FFFFFF',
    height: Platform.OS === 'ios' ? 120 : 50,
  },
  addButton: {
    backgroundColor: 'rgba(40, 167, 69, 0.8)',
    paddingVertical: 14,
    paddingHorizontal: 30,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  addButtonText: {
    fontSize: 18,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  randomizeRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 15,
  },
  randomizeButton: {
    flex: 1,
    backgroundColor: 'rgba(123, 104, 238, 0.8)',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  randomizeButtonText: {
    fontSize: 15,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  optionCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 15,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  timerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  optionLabel: {
    fontSize: 18,
    fontWeight: '600',
    color: '#E0E0E0',
  },
  toggleButton: {
    backgroundColor: 'rgba(108, 117, 125, 0.8)',
    paddingHorizontal: 20,
    paddingVertical: 8,
    borderRadius: 8,
    minWidth: 60,
    alignItems: 'center',
  },
  toggleButtonActive: {
    backgroundColor: 'rgba(40, 167, 69, 0.8)',
  },
  toggleButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  timerPickerContainer: {
    marginTop: 15,
  },
  startButton: {
    backgroundColor: '#4A90E2',
    paddingVertical: 18,
    paddingHorizontal: 40,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 30,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.6,
    shadowRadius: 8,
    elevation: 8,
  },
  startButtonText: {
    fontSize: 22,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  backButton: {
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 15,
    marginBottom: 40,
  },
  backButtonText: {
    fontSize: 16,
    color: '#E0E0E0',
    textDecorationLine: 'underline',
  },
});


