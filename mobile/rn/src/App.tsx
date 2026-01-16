import { useState, useEffect } from 'react';
import { StatusBar } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { NativeNetwork } from 'tictactoe-native';

import { GameScreen } from './GameScreen';
import { LeaderboardScreen } from './LeaderboardScreen';
import { styles } from "./styles";

type Screen = 'game' | 'leaderboard';

const App = () => {
  const [screen, setScreen] = useState<Screen>('game');

  useEffect(() => {
    NativeNetwork.configure('http://snnikitin.work:3000/api/games');
  }, []);

  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView style={styles.container}>
        {screen === 'leaderboard' ? (
          <LeaderboardScreen onBack={() => setScreen('game')} />
        ) : (
          <GameScreen onLeaderboard={() => setScreen('leaderboard')} />
        )}
      </SafeAreaView>
    </SafeAreaProvider>
  );
};

export default App;
