import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  ImageBackground,
  Dimensions,
  Linking,
  Platform,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { useNavigation, useRoute, useFocusEffect, CommonActions } from '@react-navigation/native';
import { SafeAreaView } from 'react-native-safe-area-context';
import * as Clipboard from 'expo-clipboard';
import GameManager from '../managers/GameManager';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold, Poppins_400Regular } from '@expo-google-fonts/poppins';

const { width, height } = Dimensions.get('window');

export default function GameRoomView() {
  const navigation = useNavigation();
  const route = useRoute();
  const { gameCode: initialGameCode, timerDuration: initialTimerDuration, isHost, playerName } = route.params;
  
  const [actualGameCode, setActualGameCode] = useState(initialGameCode); // Game code from server
  const [isGameStarted, setIsGameStarted] = useState(false);
  const [timeRemaining, setTimeRemaining] = useState(initialTimerDuration ? initialTimerDuration * 60 : 300);
  const [nextRoundTimerMinutes, setNextRoundTimerMinutes] = useState(initialTimerDuration || 5);
  const [playerLocation, setPlayerLocation] = useState('');
  const [isSpy, setIsSpy] = useState(false);
  const [starter, setStarter] = useState(null); // First questioner
  const [crossedOffLocations, setCrossedOffLocations] = useState(new Set());
  const [crossedOffPlayers, setCrossedOffPlayers] = useState(new Set());
  const [players, setPlayers] = useState([]);
  const [isTimeUp, setIsTimeUp] = useState(false);
  const [selectedPlayer, setSelectedPlayer] = useState(null); // Player selected but not yet voted
  const [hasVoted, setHasVoted] = useState(false); // Whether vote has been submitted
  const [votes, setVotes] = useState({}); // { voterName: votedFor } - from server
  const [tentativeVotes, setTentativeVotes] = useState({}); // { voterName: votedFor } - from server
  const [isTentativeSelected, setIsTentativeSelected] = useState(false);
  const [scores, setScores] = useState({}); // client-side scoreboard across rounds in this room
  const [gameResult, setGameResult] = useState(null);
  const [spyName, setSpyName] = useState(null);
  const [hasGuessedLocation, setHasGuessedLocation] = useState(false);
  const [availableLocations, setAvailableLocations] = useState([]);
  const [endedLocation, setEndedLocation] = useState(null);
  const [isEndingGame, setIsEndingGame] = useState(false);
  const [isObserver, setIsObserver] = useState(false); // Joined mid-game, waiting for next round
  
  const timerRef = useRef(null);
  const isEndingGameRef = useRef(false);
  const suppressVoteTapRef = useRef(false);
  const roundScoredRef = useRef(false);
  const spyNameRef = useRef(null);
  const endedLocationRef = useRef(null);
  const playersRef = useRef([]);
  const gameManager = GameManager;

  const timerOptions = [3, 4, 5, 6, 7, 8, 9, 10, 12, 15];

  const normalizeName = (s) => (s || '').trim().toLowerCase();
  const myName = gameManager?.currentPlayer?.name || playerName;
  const isSelfName = (name) => normalizeName(name) === normalizeName(myName);
  const getMapValueByName = (map, name) => {
    const target = normalizeName(name);
    for (const [k, v] of Object.entries(map || {})) {
      if (normalizeName(k) === target) return v;
    }
    return null;
  };
  const getMapValueByCanonicalName = (map, canonicalName) => {
    const target = normalizeName(canonicalName);
    for (const [k, v] of Object.entries(map || {})) {
      if (normalizeName(k) === target) return v;
    }
    return null;
  };
  const countFinalVotesForNonSpies = () => {
    const spy = spyNameRef.current;
    const nonSpies = (players || []).filter((p) => normalizeName(p.name) !== normalizeName(spy));
    const needed = nonSpies.length;

    let have = 0;
    for (const [voter, target] of Object.entries(votes || {})) {
      if (!target) continue;
      if (normalizeName(voter) === normalizeName(spy)) continue; // spy vote doesn't count for completion
      have += 1;
    }
    return { have, needed };
  };

  const setNextRoundTimer = (minutes) => {
    setNextRoundTimerMinutes(minutes);
    if (!actualGameCode) return;
    gameManager.updateTimeLimit(actualGameCode, minutes);
  };

  const updateScoresForRound = ({ spyWon, actualSpy, finalVotes }) => {
    if (roundScoredRef.current) return;
    if (!actualSpy || !actualGameCode) return;

    const defaultRow = {
      spy_wins: 0,
      resident_wins: 0,
      correct_votes: 0,
      wrong_votes: 0,
      total_games: 0,
    };

    const canonicalSpy = normalizeName(actualSpy);
    const namesFromRoster = (playersRef.current || []).map((p) => p?.name).filter(Boolean);
    const namesFromVotes = Object.keys(finalVotes || {});

    // Build a stable set of players even if local `players` state is stale/empty at end-of-round.
    const canonicalSet = new Set(
      [...namesFromRoster, ...namesFromVotes, actualSpy].map((n) => normalizeName(n)).filter(Boolean)
    );
    if (canonicalSet.size === 0) return;

    // Persist scores per-room by using a composite key: `${room}_${canonicalPlayerName}`
    setScores((prev) => {
      const next = { ...(prev || {}) };

      for (const canonicalName of canonicalSet) {
        // Prefer original casing from roster if possible
        const rosterMatch = (playersRef.current || []).find((p) => normalizeName(p?.name) === canonicalName);
        const displayName = rosterMatch?.name || canonicalName;

        const scoreKey = `${actualGameCode}_${canonicalName}`;
        if (!next[scoreKey]) next[scoreKey] = { ...defaultRow };
        next[scoreKey] = { ...next[scoreKey] };
        next[scoreKey].total_games += 1;

        if (canonicalName === canonicalSpy) {
          if (spyWon) next[scoreKey].spy_wins += 1;
        } else {
          // Resident wins not needed for your simplified scoreboard, but keep totals coherent
          if (!spyWon) next[scoreKey].resident_wins += 1;

          const v = getMapValueByCanonicalName(finalVotes || {}, canonicalName);
          if (v) {
            if (normalizeName(v) === canonicalSpy) next[scoreKey].correct_votes += 1;
            else next[scoreKey].wrong_votes += 1;
          }
        }

        // Keep a stable display name around (non-breaking add)
        next[scoreKey].display_name = displayName;
      }

      return next;
    });

    roundScoredRef.current = true;
  };
  
  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
    Poppins_400Regular,
  });

  useEffect(() => {
    playersRef.current = players || [];
  }, [players]);

  // Lock navigation - prevent swipe back and back button
  useFocusEffect(
    React.useCallback(() => {
      // Prevent back navigation
      const unsubscribe = navigation.addListener('beforeRemove', (e) => {
        // Allow navigation if we're already ending the game
        if (isEndingGameRef.current) {
          return; // Allow navigation to proceed
        }
        
        // Prevent default behavior of leaving the screen
        e.preventDefault();
        
        // Show alert to confirm leaving
        Alert.alert(
          'Leave Game?',
          isHost 
            ? 'Are you sure you want to end this game? All players will be disconnected.'
            : 'Are you sure you want to leave this game?',
          [
            { text: 'Cancel', style: 'cancel', onPress: () => {} },
            {
              text: isHost ? 'End Game' : 'Leave',
              style: 'destructive',
              onPress: () => {
                setIsEndingGame(true);
                isEndingGameRef.current = true;
                
                if (timerRef.current) {
                  clearInterval(timerRef.current);
                }
                
                // Emit event first (before removing listeners)
                if (actualGameCode) {
                  if (isHost) {
                    gameManager.endGame(actualGameCode);
                  } else {
                    gameManager.leaveGame(actualGameCode);
                  }
                }
                
                // Clean up ALL listeners after emitting
                gameManager.removeAllListeners();
                
                // Short delay to ensure events are sent, then navigate
                setTimeout(() => {
                  gameManager.disconnect();
                  // Navigate to main menu
                  navigation.dispatch(
                    CommonActions.reset({
                      index: 0,
                      routes: [{ name: 'MainMenu' }],
                    })
                  );
                }, 100);
              },
            },
          ]
        );
      });

      // Disable gestures
      navigation.setOptions({
        gestureEnabled: false,
        headerBackVisible: false,
      });

      return () => {
        unsubscribe();
        navigation.setOptions({
          gestureEnabled: true,
          headerBackVisible: true,
        });
      };
    }, [navigation, isHost, actualGameCode])
  );

  useEffect(() => {
    setupGame();
    setupWebSocketListeners();
    
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
      // Cleanup listeners
      cleanupListeners();
      
      // Only send leave_game if we're not already ending the game
      if (!isEndingGameRef.current && actualGameCode) {
        gameManager.leaveGame(actualGameCode);
      }
    };
  }, []);

  const setupGame = () => {
    // Websocket details live in `Apps/client.js` via GameManager.
    gameManager.connect();
    
    // Both host and player are already in the room (created/joined in previous views)
    // Sync state to get current room state including players list
    if (actualGameCode) {
      gameManager.syncState(actualGameCode);
    }
  };

  const setupWebSocketListeners = () => {
    // Room events
    gameManager.on('room_created', (data) => {
      setActualGameCode(data.room);
    });

    gameManager.on('joined_room', (data) => {
      // Confirmation after join
      if (data.room) {
        setActualGameCode(data.room);
      }
      // Check if joining mid-game as observer
      if (data.role === 'observer') {
        setIsObserver(true);
      }
    });

    gameManager.on('player_joined', (data) => {
      // Update players list from server
      const playerList = data.players.map(p => ({ name: p, id: p }));
      setPlayers(playerList);
    });

    gameManager.on('player_left', (data) => {
      // Update players list from server
      const playerList = data.players.map(p => ({ name: p, id: p }));
      setPlayers(playerList);
    });

    // Game events
    gameManager.on('game_started', (data) => {
      if (!data?.spy) {
        console.error('ERROR: Server did not provide spy name in game_started');
      }
      // All game data comes from server
      setAvailableLocations(data.locations || []);
      setSpyName(data.spy);
      spyNameRef.current = data.spy || null;
      setStarter(data.starter);
      setIsGameStarted(true);
      setTimeRemaining(data.time_limit_minutes * 60);
      setNextRoundTimerMinutes(data.time_limit_minutes || nextRoundTimerMinutes);
      setEndedLocation(data.location || null); // stored, but only displayed once game ends
      endedLocationRef.current = data.location || null;
      setIsTimeUp(false);
      setGameResult(null);
      setHasGuessedLocation(false);
      setSelectedPlayer(null);
      setHasVoted(false);
      setVotes({});
      setTentativeVotes({});
      setIsTentativeSelected(false);
      roundScoredRef.current = false;
      
      // If we were an observer, we're not anymore (new game started)
      setIsObserver(false);
    });

    gameManager.on('role_assignment', (data) => {
      setIsSpy(data.is_spy);
      if (!data.is_spy && data.location) {
        setPlayerLocation(data.location);
        setEndedLocation(data.location);
        endedLocationRef.current = data.location;
      }
    });

    gameManager.on('game_ended', (data) => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }

      // Prevent beforeRemove from prompting (double popup)
      isEndingGameRef.current = true;
      setIsEndingGame(true);

      // Clean up listeners immediately; then navigate
      gameManager.removeAllListeners();
      gameManager.disconnect();

      Alert.alert('Game Ended', data.reason || 'The host ended the game.', [
        {
          text: 'OK',
          onPress: () => {
            navigation.dispatch(
              CommonActions.reset({
                index: 0,
                routes: [{ name: 'MainMenu' }],
              })
            );
          },
        },
      ]);
    });

    // Voting events
    gameManager.on('vote_recorded', (data) => {
      // Update votes display - server broadcasts all votes
      setVotes(data.votes || {});
      setTentativeVotes(data.tentative_votes || {});

      const myFinal = getMapValueByName(data?.votes, myName);
      const myTentative = getMapValueByName(data?.tentative_votes, myName);

      if (myFinal) {
        setSelectedPlayer(myFinal);
        setHasVoted(true);
        setIsTentativeSelected(false);
        return;
      }

      if (myTentative) {
        setSelectedPlayer(myTentative);
        setHasVoted(false);
        setIsTentativeSelected(true);
        return;
      }

      // cleared
      setSelectedPlayer(null);
      setHasVoted(false);
      setIsTentativeSelected(false);
    });

    gameManager.on('vote_results', (data) => {
      // Only process vote_results if we haven't already ended the game due to time expiring
      // (server may send this due to time-based auto-complete, but we handle that locally)
      if (gameResult) return;
      
      // Your server code currently sets spy_won incorrectly (spy_won=False whenever there is any tally).
      // So we compute the winner from voted_spy + tie_breaker + tally size, using the known spyName.
      const actualSpy = spyNameRef.current || spyName || null;
      const votedSpy = data?.voted_spy ?? null;
      const tieBreaker = !!data?.tie_breaker;
      const tallyEmpty = !data?.tally || Object.keys(data.tally).length === 0;
      const finalVotes = data?.votes || votes;

      // Rules:
      // - If tie => spy wins
      // - If no votes => spy wins
      // - Else residents win only if votedSpy === actualSpy
      const computedSpyWon = (() => {
        if (tieBreaker || tallyEmpty) return true;
        // If we somehow don't know the spy name locally, fall back to server's flag (may be wrong on buggy server).
        if (!actualSpy) return !!data?.spy_won;
        return votedSpy !== actualSpy;
      })();

      // Debug mismatch (server flag is known-buggy, but keep this to confirm)
      if (typeof data?.spy_won === 'boolean' && data.spy_won !== computedSpyWon) {
        console.warn('Server spy_won mismatch; using computed result', {
          server: data.spy_won,
          computed: computedSpyWon,
          votedSpy,
          actualSpy,
          tieBreaker,
          tallyEmpty,
        });
      }

      updateScoresForRound({
        spyWon: computedSpyWon,
        actualSpy,
        finalVotes,
      });

      if (computedSpyWon) {
        setGameResult({
          type: 'spy_win',
          message: tieBreaker
            ? `${actualSpy} got away — no consensus.`
            : tallyEmpty
              ? `${actualSpy} got away — nobody voted.`
              : `${actualSpy} got away — you detained an innocent.`,
          message2: (endedLocationRef.current || endedLocation) ? `Location: ${endedLocationRef.current || endedLocation}` : undefined,
          spyName: actualSpy,
        });
      } else {
        setGameResult({
          type: 'residents_win',
          message: `Residents win! ${actualSpy} was caught.`,
          message2: (endedLocationRef.current || endedLocation) ? `Location: ${endedLocationRef.current || endedLocation}` : undefined,
          spyName: actualSpy,
        });
      }
    });

    // Spy guess events
    gameManager.on('spy_guess_result', (data) => {
      setHasGuessedLocation(true);
      if (data?.actual_location) {
        setEndedLocation(data.actual_location);
        endedLocationRef.current = data.actual_location;
      }
      const actualSpy = spyNameRef.current || data?.guessed_by || spyName || null;
      if (data.success) {
        updateScoresForRound({
          spyWon: true,
          actualSpy,
          finalVotes: votes,
        });
        // Spy guessed correctly
        setGameResult({
          type: 'spy_win',
          message: `${actualSpy} guessed the location correctly and got away.`,
          message2: data?.actual_location ? `Location: ${data.actual_location}` : undefined,
          spyName: actualSpy,
        });
      } else {
        updateScoresForRound({
          spyWon: false,
          actualSpy,
          finalVotes: votes,
        });
        // Spy guessed incorrectly
        setGameResult({
          type: 'residents_win',
          message: `${actualSpy} guessed the location wrong. Residents win!`,
          message2: data?.actual_location ? `Location: ${data.actual_location}` : undefined,
          spyName: actualSpy,
        });
      }
    });

    // State sync for reconnection
    gameManager.on('state_sync', (data) => {
      if (data.time_limit_minutes) {
        setNextRoundTimerMinutes(data.time_limit_minutes);
      }

      // Check if player is observer (joined mid-game)
      if (data.role === 'observer' && data.status === 'started') {
        setIsObserver(true);
        setTimeRemaining(data.time_remaining_seconds || 0);
        setPlayers(data.players?.map(p => ({ name: p, id: p })) || []);
        return;
      }

      // Restore full game state from server
      if (data.status === 'started') {
        setIsGameStarted(true);
        setIsObserver(false);
        setAvailableLocations(data.locations || []);
        setSpyName(data.spy);
        spyNameRef.current = data.spy || null;
        setStarter(data.starter);
        setTimeRemaining(data.time_remaining_seconds || 0);
        setPlayers(data.players?.map(p => ({ name: p, id: p })) || []);
        setIsSpy(data.is_spy || false);
        if (!data.is_spy && data.location) {
          setPlayerLocation(data.location);
          setEndedLocation(data.location);
          endedLocationRef.current = data.location;
        }
        setVotes(data.votes || {});
        setTentativeVotes(data.tentative_votes || {});
        // Restore hasVoted state - if we already voted, lock it
        if (data.votes && data.votes[playerName]) {
          setHasVoted(true);
        } else {
          setHasVoted(false);
        }
      } else if (data.status === 'waiting') {
        setIsGameStarted(false);
        setIsObserver(false);
        setPlayers(data.players?.map(p => ({ name: p, id: p })) || []);
      }
    });

    // Room state updates
    gameManager.on('room_state', (data) => {
      if (data.players) {
        setPlayers(data.players.map(p => ({ name: p, id: p })));
      }
    });

    // Timer updates for next round (server broadcasts when room timer changes)
    gameManager.on('time_limit_updated', (data) => {
      if (data?.minutes) {
        setNextRoundTimerMinutes(data.minutes);
      }
    });

    // Error handling - server emits 'error' event with message
    gameManager.on('error', (data) => {
      Alert.alert('Error', data.message || 'An error occurred');
    });
  };

  const cleanupListeners = () => {
    // Remove all listeners
    gameManager.off('room_created');
    gameManager.off('joined_room');
    gameManager.off('player_joined');
    gameManager.off('player_left');
    gameManager.off('game_started');
    gameManager.off('role_assignment');
    gameManager.off('game_ended');
    gameManager.off('vote_recorded');
    gameManager.off('vote_results');
    gameManager.off('spy_guess_result');
    gameManager.off('state_sync');
    gameManager.off('room_state');
    gameManager.off('time_limit_updated');
    gameManager.off('error');
  };

  // Timer effect
  useEffect(() => {
    if (isGameStarted && timeRemaining > 0 && !gameResult) {
      timerRef.current = setInterval(() => {
        setTimeRemaining((prev) => {
          if (prev <= 1) {
            clearInterval(timerRef.current);
            handleTimeUp();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, [isGameStarted, timeRemaining, gameResult]);

  const handleTimeUp = () => {
    setIsTimeUp(true);
    
    // When time expires, spy wins automatically (time ran out = spy escaped)
    const actualSpy = spyNameRef.current || spyName || null;
    updateScoresForRound({
      spyWon: true,
      actualSpy,
      finalVotes: votes,
    });
    
    setGameResult({
      type: 'spy_win',
      message: `Time's up! ${actualSpy} escaped.`,
      message2: (endedLocationRef.current || endedLocation) ? `Location: ${endedLocationRef.current || endedLocation}` : undefined,
      spyName: actualSpy,
    });
  };

  const startGame = () => {
    if (!actualGameCode) return;
    gameManager.startGame(actualGameCode, nextRoundTimerMinutes);
  };

  const toggleLocation = (location) => {
    if (gameResult) return;
    
    setCrossedOffLocations((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(location)) {
        newSet.delete(location);
      } else {
        newSet.add(location);
      }
      return newSet;
    });
  };

  const togglePlayer = (playerNameToToggle) => {
    if (gameResult) return;
    
    setCrossedOffPlayers((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(playerNameToToggle)) {
        newSet.delete(playerNameToToggle);
      } else {
        newSet.add(playerNameToToggle);
      }
      return newSet;
    });
  };

  const handleLocationGuess = (location) => {
    if (!isSpy || hasGuessedLocation || gameResult || !actualGameCode) return;
    
    Alert.alert(
      'Confirm Location Guess',
      `Are you sure you are at ${location}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes',
          onPress: () => {
            gameManager.guessLocation(actualGameCode, location);
          },
        },
      ]
    );
  };

  const handlePlayerTap = (playerNameToSelect) => {
    if (suppressVoteTapRef.current) return;
    if (!actualGameCode || isSelfName(playerNameToSelect) || !isGameStarted || gameResult) return;

    const myFinalVote = getMapValueByName(votes, myName);
    const myTentativeVote = getMapValueByName(tentativeVotes, myName);

    // If tapping the selected player, clear BOTH tentative + final (per your rule).
    if (selectedPlayer === playerNameToSelect) {
      gameManager.voteForSpy(actualGameCode, null, true);
      gameManager.voteForSpy(actualGameCode, null, false);
      // don't mutate local state here; wait for vote_recorded to confirm clear
      return;
    }

    // If a different player is selected already, clear current selection first (tap again to pick new)
    if (selectedPlayer && selectedPlayer !== playerNameToSelect) {
      if (myFinalVote || myTentativeVote) {
        gameManager.voteForSpy(actualGameCode, null, true);
        gameManager.voteForSpy(actualGameCode, null, false);
      }
      return;
    }

    // No selection yet -> set tentative (tap)
    gameManager.voteForSpy(actualGameCode, playerNameToSelect, true);
  };

  const handlePlayerLongPress = (playerNameToSelect) => {
    if (!actualGameCode || isSelfName(playerNameToSelect) || !isGameStarted || gameResult) return;

    const myFinalVote = getMapValueByName(votes, myName);
    const myTentativeVote = getMapValueByName(tentativeVotes, myName);

    // Prevent onPress from firing after onLongPress
    suppressVoteTapRef.current = true;
    setTimeout(() => {
      suppressVoteTapRef.current = false;
    }, 250);

    // If a different player is selected already, clear current selection first
    if (selectedPlayer && selectedPlayer !== playerNameToSelect) {
      if (myFinalVote || myTentativeVote) {
        gameManager.voteForSpy(actualGameCode, null, true);
        gameManager.voteForSpy(actualGameCode, null, false);
      }
      return;
    }

    // Set final vote (long press)
    gameManager.voteForSpy(actualGameCode, playerNameToSelect, false);
  };

  useEffect(() => {
    // Keep UI selection consistent with server state (handles edge cases / out-of-order events)
    if (!isGameStarted || !actualGameCode) return;

    const myFinalVote = getMapValueByName(votes, myName);
    const myTentativeVote = getMapValueByName(tentativeVotes, myName);

    if (!myFinalVote && !myTentativeVote) {
      if (selectedPlayer || hasVoted || isTentativeSelected) {
        setSelectedPlayer(null);
        setHasVoted(false);
        setIsTentativeSelected(false);
      }
      return;
    }

    if (myFinalVote) {
      if (selectedPlayer !== myFinalVote || !hasVoted) {
        setSelectedPlayer(myFinalVote);
        setHasVoted(true);
        setIsTentativeSelected(false);
      }
      return;
    }

    if (myTentativeVote) {
      if (selectedPlayer !== myTentativeVote || !isTentativeSelected) {
        setSelectedPlayer(myTentativeVote);
        setHasVoted(false);
        setIsTentativeSelected(true);
      }
    }
  }, [votes, tentativeVotes, selectedPlayer, hasVoted, isTentativeSelected, myName, isGameStarted, actualGameCode]);

  const handleEndGame = () => {
    if (isEndingGameRef.current) return; // Prevent multiple triggers
    
    Alert.alert(
      'End Game',
      isHost
        ? 'Are you sure you want to end this game? All players will be disconnected.'
        : 'Are you sure you want to leave this game?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: isHost ? 'End Game' : 'Leave',
          style: 'destructive',
          onPress: () => {
            setIsEndingGame(true); // Set flag
            isEndingGameRef.current = true; // Set ref flag
            
            if (timerRef.current) {
              clearInterval(timerRef.current);
            }
            
            // Emit event first (before removing listeners)
            if (actualGameCode) {
              if (isHost) {
                gameManager.endGame(actualGameCode);
              } else {
                gameManager.leaveGame(actualGameCode);
              }
            }
            
            // Clean up ALL listeners after emitting
            gameManager.removeAllListeners();
            
            // Short delay to ensure events are sent, then navigate
            setTimeout(() => {
              gameManager.disconnect();
              // Use reset to prevent going back
              navigation.dispatch(
                CommonActions.reset({
                  index: 0,
                  routes: [{ name: 'MainMenu' }],
                })
              );
            }, 100);
          },
        },
      ]
    );
  };

  const handleNewGame = () => {
    if (!actualGameCode) return;
    
    // Reset game state
    setIsGameStarted(false);
    setIsTimeUp(false);
    setPlayerLocation('');
    setIsSpy(false);
    setStarter(null);
    setCrossedOffLocations(new Set());
    setCrossedOffPlayers(new Set());
    setGameResult(null);
    setSelectedPlayer(null);
    setHasVoted(false);
    setVotes({});
    setHasGuessedLocation(false);
    
    // Start new game
    startGame();
  };

  const shareGameCode = async () => {
    if (!actualGameCode) return;
    
    const message = `Join my BluffLocation game! Code: ${actualGameCode}`;
    const url = `sms:&body=${encodeURIComponent(message)}`;

    try {
      const supported = await Linking.canOpenURL(url);
      if (supported) {
        await Linking.openURL(url);
      } else {
        await Clipboard.setStringAsync(actualGameCode);
        Alert.alert('Copied to Clipboard', 'Game code copied to clipboard!');
      }
    } catch (error) {
      await Clipboard.setStringAsync(actualGameCode);
      Alert.alert('Copied to Clipboard', 'Game code copied to clipboard!');
    }
  };

  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  };

  const isFirstQuestioner = starter === playerName;

  if (!cinzelLoaded || !poppinsLoaded) {
    return null;
  }

  // Waiting room for mid-game joiners
  if (isObserver) {
    return (
      <ImageBackground
        source={require('../../assets/background.png')}
        style={styles.background}
        resizeMode="cover"
      >
        <SafeAreaView style={styles.safeArea}>
          <View style={styles.overlay}>
            <Text style={[styles.title, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              Waiting Room
            </Text>

            <View style={styles.waitingRoomContainer}>
              <Text style={[styles.waitingRoomTitle, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                Game in Progress
              </Text>
              
              <Text style={[styles.waitingRoomMessage, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
                A game is currently being played. You'll join the next round!
              </Text>

              <View style={styles.waitingTimerBox}>
                <Text style={[styles.waitingTimerLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                  Time Remaining
                </Text>
                <Text style={[styles.waitingTimerValue, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
                  {formatTime(timeRemaining)}
                </Text>
              </View>

              <View style={styles.waitingPlayersSection}>
                <Text style={[styles.waitingPlayersLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                  Players in Game
                </Text>
                <View style={styles.waitingPlayersGrid}>
                  {players.map((player) => (
                    <View key={player.id || player.name} style={styles.waitingPlayerCard}>
                      <Text style={[styles.waitingPlayerText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
                        {player.name}
                      </Text>
                    </View>
                  ))}
                </View>
              </View>
            </View>

            <TouchableOpacity
              style={[styles.controlButton, styles.leaveButton, styles.waitingRoomLeaveButton]}
              onPress={handleEndGame}
            >
              <Text style={[styles.controlButtonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                Leave Room
              </Text>
            </TouchableOpacity>
          </View>
        </SafeAreaView>
      </ImageBackground>
    );
  }

  if (!isGameStarted) {
    return (
      <ImageBackground
        source={require('../../assets/background.png')}
        style={styles.background}
        resizeMode="cover"
      >
        <SafeAreaView style={styles.safeArea}>
          <View style={styles.overlay}>
            <Text style={[styles.title, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              Game Room
            </Text>

            <View style={styles.codeContainer}>
              <Text style={styles.codeLabel}>Game Code:</Text>
              <TouchableOpacity style={styles.codeDisplay} onPress={shareGameCode}>
                <Text style={styles.codeText}>{actualGameCode || 'Loading...'}</Text>
                <Text style={styles.shareHint}>Tap to share</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.playersSection}>
              <Text style={[styles.sectionTitle, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>Players</Text>
              <View style={styles.playersGrid}>
                {players.length > 0 ? (
                  players.map((player) => (
                    <View key={player.id || player.name} style={styles.playerCard}>
                      <Text style={[styles.playerText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                        {player.name}
                      </Text>
                    </View>
                  ))
                ) : (
                  <Text style={[styles.noPlayersText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>No players yet...</Text>
                )}
              </View>
            </View>

            <View style={styles.nextRoundTimerContainer}>
              <Text style={[styles.nextRoundTimerLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                Timer Duration
              </Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={nextRoundTimerMinutes}
                  onValueChange={(itemValue) => setNextRoundTimer(itemValue)}
                  style={styles.picker}
                  itemStyle={styles.pickerItem}
                  dropdownIconColor="#FFFFFF"
                >
                  {timerOptions.map((minutes) => (
                    <Picker.Item key={minutes} label={`${minutes} minutes`} value={minutes} />
                  ))}
                </Picker>
              </View>
            </View>

            {players.length >= 3 ? (
              <TouchableOpacity style={styles.startButton} onPress={startGame}>
                <Text style={[styles.startButtonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                  Start Game
                </Text>
              </TouchableOpacity>
            ) : (
              <Text style={[styles.waitingText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                Waiting for players (minimum 3)...
              </Text>
            )}

            <TouchableOpacity
              style={[styles.controlButton, styles.leaveButton, styles.waitingScreenButton]}
              onPress={handleEndGame}
            >
              <Text style={[styles.controlButtonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                {isHost ? 'End Game' : 'Leave Game'}
              </Text>
            </TouchableOpacity>
          </View>
        </SafeAreaView>
      </ImageBackground>
    );
  }

  return (
    <ImageBackground
      source={require('../../assets/background.png')}
      style={styles.background}
      resizeMode="cover"
    >
      <SafeAreaView style={styles.safeArea}>
        {/* Game Result Modal */}
        {gameResult && (
          <View style={styles.resultOverlay}>
            <View style={styles.resultCard}>
              <Text style={[styles.resultTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
                {gameResult.type === 'spy_win' ? 'Spy Wins!' : 'Residents Win!'}
              </Text>

              <ScrollView style={styles.resultScroll} contentContainerStyle={styles.resultScrollContent}>
                <Text style={[styles.resultMessage, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
                  {gameResult.message}
                  {gameResult.spyName ? (
                    <>
                      {' (Spy: '}
                      <Text style={[styles.spyNameText, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
                        {gameResult.spyName}
                      </Text>
                      {')'}
                    </>
                  ) : null}
                </Text>
                {gameResult.message2 && (
                  <Text style={[styles.resultMessage, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
                    {gameResult.message2}
                  </Text>
                )}

                <View style={styles.nextRoundTimerContainer}>
                  <Text style={[styles.nextRoundTimerLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                    Next Round Timer
                  </Text>
                  <View style={styles.pickerWrapper}>
                    <Picker
                      selectedValue={nextRoundTimerMinutes}
                      onValueChange={(itemValue) => setNextRoundTimer(itemValue)}
                      style={styles.picker}
                      itemStyle={styles.pickerItem}
                      dropdownIconColor="#FFFFFF"
                    >
                      {timerOptions.map((minutes) => (
                        <Picker.Item key={minutes} label={`${minutes} minutes`} value={minutes} />
                      ))}
                    </Picker>
                  </View>
                </View>

                <View style={styles.scoreboardContainer}>
                  <View style={styles.scoreboardHeaderRow}>
                    <Text
                      style={[
                        styles.scoreboardHeaderCell,
                        styles.scoreboardNameCell,
                        poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' },
                      ]}
                    >
                      Player
                    </Text>
                    <Text style={[styles.scoreboardHeaderCell, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                      Spy Wins
                    </Text>
                    <Text style={[styles.scoreboardHeaderCell, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                      Correct
                    </Text>
                  </View>

                  {Object.entries(scores || {})
                    .filter(([key]) => actualGameCode && key.startsWith(`${actualGameCode}_`))
                    .sort((a, b) => {
                      const aa = a[1] || {};
                      const bb = b[1] || {};
                      const as = (aa.spy_wins || 0) + (aa.correct_votes || 0);
                      const bs = (bb.spy_wins || 0) + (bb.correct_votes || 0);
                      return bs - as;
                    })
                    .map(([key, row]) => {
                      const name = row?.display_name || (actualGameCode ? key.replace(`${actualGameCode}_`, '') : key);
                      return (
                        <View key={key} style={styles.scoreboardRow}>
                          <Text
                            style={[
                              styles.scoreboardCell,
                              styles.scoreboardNameCell,
                              poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' },
                            ]}
                          >
                            {name}
                          </Text>
                          <Text style={[styles.scoreboardCell, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                            {row.spy_wins || 0}
                          </Text>
                          <Text style={[styles.scoreboardCell, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                            {row.correct_votes || 0}
                          </Text>
                        </View>
                      );
                    })}
                </View>
              </ScrollView>

              <TouchableOpacity
                style={styles.resultButton}
                onPress={() => {
                  handleNewGame();
                }}
              >
                <Text style={[styles.resultButtonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                  New Game
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        <View style={styles.gameContainerOverlay}>
          <View style={styles.gameContainer}>
            {/* Timer */}
            <View style={styles.timerContainer}>
              <View style={styles.timerContent}>
                {isTimeUp && !gameResult ? (
                  <>
                    <Text style={[styles.timerLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>Time's Up!</Text>
                    <Text style={[styles.timeUpText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                      {isSpy ? 'Calculating Results...' : 'Calculating Results...'}
                    </Text>
                  </>
                ) : (
                  <>
                    <Text style={[styles.timerLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>Time Remaining</Text>
                    <Text style={[styles.timer, timeRemaining < 60 && styles.timerWarning]}>
                      {formatTime(timeRemaining)}
                    </Text>
                  </>
                )}
              </View>
            </View>

            <View style={styles.nextRoundTimerInline}>
              <Text style={[styles.nextRoundTimerInlineText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
                Next Round Timer
              </Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={nextRoundTimerMinutes}
                  onValueChange={(itemValue) => setNextRoundTimer(itemValue)}
                  style={styles.picker}
                  itemStyle={styles.pickerItem}
                  dropdownIconColor="#FFFFFF"
                >
                  {timerOptions.map((minutes) => (
                    <Picker.Item key={minutes} label={`${minutes} minutes`} value={minutes} />
                  ))}
                </Picker>
              </View>
            </View>

            <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
              {/* Location/Spy Display */}
              <View style={[styles.locationContainer, isSpy && styles.spyContainer]}>
                {isSpy ? (
                  <>
                    <Text style={[styles.locationLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>You are the</Text>
                    <Text style={[styles.spyText, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>SPY</Text>
                    <Text style={[styles.spyHint, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>Figure out the location!</Text>
                    {isFirstQuestioner && (
                      <Text style={[styles.firstQuestionerBadge, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>You ask first</Text>
                    )}
                  </>
                ) : (
                  <>
                    <Text style={[styles.locationLabel, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>Location:</Text>
                    <Text style={[styles.locationText, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>{playerLocation}</Text>
                    {isFirstQuestioner && (
                      <Text style={[styles.firstQuestionerBadge, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>You ask first</Text>
                    )}
                  </>
                )}
              </View>

              {/* Locations */}
              <View style={styles.section}>
                {isSpy && !hasGuessedLocation && !gameResult && (
                  <Text style={[styles.spyHintText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>Hold down a location to guess</Text>
                )}
                <View style={styles.grid}>
                  {availableLocations.map((location) => (
                    <TouchableOpacity
                      key={location}
                      style={[
                        styles.card,
                        crossedOffLocations.has(location) && styles.cardCrossedOff,
                      ]}
                      onPress={() => toggleLocation(location)}
                      onLongPress={() => {
                        if (isSpy && !hasGuessedLocation && !gameResult) {
                          handleLocationGuess(location);
                        }
                      }}
                      delayLongPress={500}
                    >
                      <Text
                        style={[
                          styles.cardText,
                          crossedOffLocations.has(location) && styles.cardTextCrossedOff,
                          poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }
                        ]}
                      >
                        {location}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>

              {/* Divider */}
              <View style={styles.divider} />

              {/* Players */}
              <View style={styles.section}>
                {isGameStarted && !gameResult ? (
                  <View>
                    <Text style={[styles.votingInstructions, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                      {(() => {
                        const { have, needed } = countFinalVotesForNonSpies();
                        const progress = `Final votes: ${have}/${needed}.`;
                        if (hasVoted) return `${progress} Your final vote is in. Tap selected player to clear.`;
                        if (isTentativeSelected) return `${progress} Tentative selected. Hold selected player for final.`;
                        return `${progress} Tap for tentative, hold for final. Results broadcast when all non-spies submit final.`;
                      })()}
                    </Text>
                    <View style={styles.grid}>
                      {players.length > 0 ? (
                        players.map((player) => {
                          const myFinalChoice = getMapValueByName(votes, myName);
                          const myTentativeChoice = getMapValueByName(tentativeVotes, myName);
                          const myFinalVoteForThisPlayer = myFinalChoice === player.name;
                          const myTentativeVoteForThisPlayer =
                            !myFinalChoice && myTentativeChoice === player.name;
                          const isTentative = myTentativeVoteForThisPlayer && !myFinalVoteForThisPlayer;

                          // Privacy: only show FINAL votes to everyone (tentative votes should not affect public counts)
                          const finalCount = Object.values(votes || {}).filter((v) => v === player.name).length;
                          const voteCount = finalCount;
                          const badgeStyle = undefined;
                          
                          return (
                            <TouchableOpacity
                              key={player.id || player.name}
                              style={[
                                styles.card,
                                isTentative && selectedPlayer === player.name && styles.cardTentative,
                                myFinalVoteForThisPlayer && styles.cardVoted,
                              ]}
                              onPress={() => handlePlayerTap(player.name)}
                              onLongPress={() => handlePlayerLongPress(player.name)}
                              delayLongPress={500}
                              disabled={
                                isSelfName(player.name) ||
                                false
                              }
                            >
                              <Text
                                style={[
                                  styles.cardText,
                                  isTentative && styles.cardTextTentative,
                                  myFinalVoteForThisPlayer && styles.cardTextVoted,
                                  poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }
                                ]}
                              >
                                {player.name}
                                {myFinalVoteForThisPlayer && ' ✓'}
                                {isTentative && ' ?'}
                              </Text>
                              {voteCount > 0 && (
                                <View style={[styles.voteCountBadge, badgeStyle]}>
                                  <Text style={styles.voteCountText}>{voteCount}</Text>
                                </View>
                              )}
                            </TouchableOpacity>
                          );
                        })
                      ) : (
                        <Text style={[styles.noPlayersText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>No players yet...</Text>
                      )}
                    </View>
                  </View>
                ) : (
                  <View style={styles.grid}>
                    {players.length > 0 ? (
                      players.map((player) => (
                        <TouchableOpacity
                          key={player.id || player.name}
                          style={[
                            styles.card,
                            crossedOffPlayers.has(player.name) && styles.cardCrossedOff,
                          ]}
                          onPress={() => togglePlayer(player.name)}
                        >
                          <Text
                            style={[
                              styles.cardText,
                              crossedOffPlayers.has(player.name) && styles.cardTextCrossedOff,
                              poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }
                            ]}
                          >
                            {player.name}
                          </Text>
                        </TouchableOpacity>
                      ))
                    ) : (
                      <Text style={[styles.noPlayersText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>No players yet...</Text>
                    )}
                  </View>
                )}
              </View>

              {/* End Game / New Game Buttons */}
              <View style={styles.endGameContainer}>
                <View style={styles.buttonRow}>
                  <TouchableOpacity
                    style={[styles.controlButton, styles.newGameButton]}
                    onPress={handleNewGame}
                  >
                    <Text style={[styles.controlButtonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                      ↻ New Game
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.controlButton, styles.leaveButton, !isHost && styles.leaveButtonFull]}
                    onPress={handleEndGame}
                  >
                    <Text style={[styles.controlButtonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
                      {isHost ? 'End Game' : 'Leave Game'}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            </ScrollView>
          </View>
        </View>
      </SafeAreaView>
    </ImageBackground>
  );
}

// Styles remain the same - copying from original file structure
const styles = StyleSheet.create({
  background: {
    flex: 1,
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
  },
  safeArea: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  gameContainerOverlay: {
    flex: 1,
  },
  gameContainer: {
    flex: 1,
    position: 'relative',
  },
  overlay: {
    flex: 1,
    padding: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 42,
    fontWeight: '700',
    marginBottom: 30,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 8,
    letterSpacing: 1,
  },
  codeContainer: {
    width: '100%',
    alignItems: 'center',
    marginBottom: 30,
  },
  codeLabel: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 10,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  codeDisplay: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    padding: 20,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    alignItems: 'center',
    minWidth: 200,
  },
  codeText: {
    fontSize: 32,
    fontWeight: 'bold',
    fontFamily: 'monospace',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
    marginBottom: 5,
  },
  shareHint: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    fontStyle: 'italic',
  },
  waitingText: {
    fontSize: 18,
    color: '#FFFFFF',
    marginBottom: 30,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  nextRoundTimerContainer: {
    width: '100%',
    maxWidth: 400,
    backgroundColor: 'rgba(0, 0, 0, 0.35)',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    marginBottom: 18,
    alignItems: 'center',
  },
  nextRoundTimerLabel: {
    fontSize: 16,
    color: '#FFFFFF',
    marginBottom: 10,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  nextRoundTimerInline: {
    marginHorizontal: 20,
    marginBottom: 10,
    alignItems: 'center',
  },
  nextRoundTimerInlineText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.85)',
    marginBottom: 8,
  },
  startButton: {
    backgroundColor: '#D4A574',
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#D4A574',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 8,
  },
  startButtonText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
    paddingTop: 10,
    paddingBottom: 100,
  },
  timerContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    padding: 20,
    paddingTop: 15,
    borderRadius: 15,
    marginTop: 10,
    marginHorizontal: 20,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  timerContent: {
    flex: 1,
    alignItems: 'center',
  },
  timerLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 8,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  timer: {
    fontSize: 48,
    fontWeight: 'bold',
    fontFamily: 'monospace',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 6,
  },
  timerWarning: {
    color: '#FF6B6B',
  },
  timeUpText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FF6B6B',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 6,
    marginTop: 8,
  },
  controlButton: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    flex: 1,
    maxWidth: 180,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
  waitingScreenButton: {
    marginTop: 30,
    flex: 0,
    maxWidth: 200,
    width: 200,
  },
  newGameButton: {
    backgroundColor: '#D4A574',
    borderWidth: 2,
    borderColor: '#D4A574',
  },
  leaveButton: {
    backgroundColor: '#FF3B30',
    borderWidth: 2,
    borderColor: '#FF3B30',
  },
  leaveButtonFull: {
    maxWidth: '100%',
  },
  controlButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  playersSection: {
    marginBottom: 25,
    width: '100%',
    alignItems: 'center',
  },
  playersGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    width: '100%',
  },
  playerCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 15,
    margin: 5,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  playerText: {
    fontSize: 16,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 15,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  locationContainer: {
    backgroundColor: 'rgba(74, 158, 191, 0.2)',
    padding: 20,
    borderRadius: 15,
    alignItems: 'center',
    marginBottom: 25,
    borderWidth: 1,
    borderColor: 'rgba(74, 158, 191, 0.4)',
  },
  spyContainer: {
    backgroundColor: 'rgba(255, 59, 48, 0.2)',
    borderColor: 'rgba(255, 59, 48, 0.4)',
  },
  locationLabel: {
    fontSize: 20,
    marginBottom: 10,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  locationText: {
    fontSize: 36,
    fontWeight: 'bold',
    textAlign: 'center',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 6,
  },
  spyText: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#FF6B6B',
    marginVertical: 10,
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 6,
  },
  spyHint: {
    fontSize: 16,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  firstQuestionerBadge: {
    marginTop: 10,
    paddingVertical: 5,
    paddingHorizontal: 10,
    borderRadius: 8,
    backgroundColor: 'rgba(212, 165, 116, 0.8)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  section: {
    marginBottom: 25,
  },
  divider: {
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    marginVertical: 20,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  card: {
    width: '30%',
    minWidth: 100,
    height: 50,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
  },
  cardCrossedOff: {
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    opacity: 0.5,
  },
  cardText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#FFFFFF',
    textAlign: 'center',
    paddingHorizontal: 5,
    textShadowColor: 'rgba(0, 0, 0, 0.6)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  cardTextCrossedOff: {
    textDecorationLine: 'line-through',
    color: 'rgba(255, 255, 255, 0.5)',
  },
  noPlayersText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.6)',
    textAlign: 'center',
    width: '100%',
    paddingVertical: 20,
    textShadowColor: 'rgba(0, 0, 0, 0.6)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  spyHintText: {
    fontSize: 14,
    color: '#D4A574',
    textAlign: 'center',
    marginBottom: 12,
    fontStyle: 'italic',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  votingInstructions: {
    fontSize: 16,
    color: '#FFFFFF',
    marginBottom: 15,
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  cardSelected: {
    backgroundColor: 'rgba(74, 158, 191, 0.4)',
    borderColor: 'rgba(74, 158, 191, 0.8)',
  },
  cardTentative: {
    backgroundColor: 'rgba(212, 165, 116, 0.22)',
    borderColor: 'rgba(212, 165, 116, 0.8)',
  },
  cardVoted: {
    backgroundColor: 'rgba(255, 59, 48, 0.3)',
    borderColor: 'rgba(255, 59, 48, 0.6)',
  },
  cardTextSelected: {
    color: '#4A9EBF',
    fontWeight: 'bold',
  },
  cardTextTentative: {
    color: '#D4A574',
    fontWeight: 'bold',
  },
  cardTextVoted: {
    color: '#FF3B30',
    fontWeight: 'bold',
  },
  voteCountBadge: {
    position: 'absolute',
    top: -8,
    right: -8,
    backgroundColor: '#FF3B30',
    borderRadius: 10,
    minWidth: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  mixedVotesBadge: {
    backgroundColor: '#D4A574',
  },
  tentativeOnlyBadge: {
    backgroundColor: '#4A9EBF',
  },
  voteCountText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#FFFFFF',
    fontFamily: 'monospace',
  },
  voteCount: {
    fontSize: 18,
    fontWeight: '700',
    color: '#D4A574',
    marginTop: 4,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  scoreboardContainer: {
    marginTop: 8,
    marginBottom: 6,
    width: '100%',
  },
  scoreboardHeaderRow: {
    flexDirection: 'row',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.15)',
    marginBottom: 6,
  },
  scoreboardRow: {
    flexDirection: 'row',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.08)',
  },
  scoreboardHeaderCell: {
    flex: 1,
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.75)',
    textAlign: 'center',
  },
  scoreboardCell: {
    flex: 1,
    fontSize: 14,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  scoreboardNameCell: {
    flex: 2,
    textAlign: 'left',
    paddingRight: 8,
  },
  endGameContainer: {
    marginTop: 30,
    marginBottom: 20,
    alignItems: 'center',
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'center',
    width: '100%',
  },
  resultOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: width,
    height: height,
    backgroundColor: 'rgba(0, 0, 0, 0.85)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  resultCard: {
    backgroundColor: 'rgba(20, 20, 30, 0.95)',
    borderRadius: 16,
    padding: 32,
    margin: 20,
    maxWidth: '90%',
    maxHeight: '85%',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.5,
    shadowRadius: 16,
    elevation: 10,
  },
  resultScroll: {
    width: '100%',
    marginTop: 6,
    marginBottom: 10,
  },
  resultScrollContent: {
    paddingBottom: 10,
  },
  resultTitle: {
    fontSize: 36,
    fontWeight: '700',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 20,
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 8,
  },
  resultMessage: {
    fontSize: 18,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 12,
    lineHeight: 26,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  spyNameText: {
    color: '#FF3B30',
    fontWeight: '900',
    fontSize: 18,
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  resultButton: {
    backgroundColor: '#D4A574',
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 8,
    marginTop: 24,
    borderWidth: 2,
    borderColor: '#D4A574',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 8,
  },
  resultButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  // Waiting Room Styles
  waitingRoomContainer: {
    width: '100%',
    alignItems: 'center',
    paddingVertical: 30,
  },
  waitingRoomTitle: {
    fontSize: 32,
    color: '#FFFFFF',
    marginBottom: 16,
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  waitingRoomMessage: {
    fontSize: 18,
    color: 'rgba(255, 255, 255, 0.85)',
    marginBottom: 30,
    textAlign: 'center',
    paddingHorizontal: 20,
    lineHeight: 26,
  },
  waitingTimerBox: {
    backgroundColor: 'rgba(20, 20, 30, 0.8)',
    borderRadius: 16,
    padding: 24,
    marginBottom: 30,
    borderWidth: 2,
    borderColor: 'rgba(212, 165, 116, 0.5)',
    alignItems: 'center',
    minWidth: 200,
  },
  waitingTimerLabel: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 8,
  },
  waitingTimerValue: {
    fontSize: 48,
    color: '#D4A574',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  waitingPlayersSection: {
    width: '100%',
    paddingHorizontal: 20,
  },
  waitingPlayersLabel: {
    fontSize: 18,
    color: '#FFFFFF',
    marginBottom: 12,
    textAlign: 'center',
  },
  waitingPlayersGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 8,
  },
  waitingPlayerCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  waitingPlayerText: {
    fontSize: 14,
    color: '#FFFFFF',
  },
  waitingRoomLeaveButton: {
    marginTop: 40,
  },
});
