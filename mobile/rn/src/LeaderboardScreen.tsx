import { useEffect, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, ActivityIndicator } from 'react-native';
import { NativeDatabase } from 'tictactoe-native';
import type { LeaderboardEntry } from 'tictactoe-native';
import { colors } from './colors';
import { styles } from './styles';

type Props = {
  onBack: () => void;
};

const fmtDuration = (sec: number) => {
  if (sec < 60) return `${sec}s`;
  if (sec < 3600) return `${Math.floor(sec / 60)}m`;
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return `${h}h ${m}m`;
};

export const LeaderboardScreen = ({ onBack }: Props) => {
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    interface LeaderboardResponse {
      leaderboard?: LeaderboardEntry[] | undefined;
    }

    NativeDatabase.getLeaderboard()
      .then((res: LeaderboardResponse | undefined) => {
      if (isMounted && res?.leaderboard) {
        setEntries(res.leaderboard);
      }
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });
    return () => { isMounted = false; };
  }, []);

  const renderItem = ({ item, index }: { item: LeaderboardEntry; index: number }) => {
    const winRate = item.total > 0 ? Math.round((item.wins / item.total) * 100) : 0;

    return (
      <View style={styles.row}>
        <Text style={styles.rank}>#{index + 1}</Text>
        <View style={styles.info}>
          <Text style={styles.name}>{item.name}</Text>
          <Text style={styles.stats}>
            Best streak: {item.bestStreak} ({fmtDuration(item.streakDuration)}) | Win rate: {winRate}% ({item.wins}/{item.total})
          </Text>
        </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack}>
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Leaderboard</Text>
        <View style={styles.placeholder} />
      </View>

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={colors.accent} />
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      ) : entries.length === 0 ? (
        <View style={styles.center}>
          <Text style={styles.empty}>No games yet</Text>
        </View>
      ) : (
        <FlatList
          data={entries}
          renderItem={renderItem}
          keyExtractor={item => String(item.playerId)}
          contentContainerStyle={styles.list}
        />
      )}
    </View>
  );
};
