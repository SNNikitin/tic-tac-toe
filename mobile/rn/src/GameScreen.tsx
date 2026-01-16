import { useEffect, useCallback, useState, useRef } from 'react';
import {
  View,
  Text,
  Alert,
  TouchableOpacity,
  Modal,
  TextInput,
  KeyboardAvoidingView,
  TouchableWithoutFeedback,
  Keyboard,
} from 'react-native';
import { NativeGame, NativeDatabase, NativeNetwork } from 'tictactoe-native';
import type { GameState, Difficulty, GameResult } from 'tictactoe-native';
import { colors } from './colors';
import { styles } from './styles';

type Props = {
  onLeaderboard: () => void;
};

type ModalState =
  | { type: 'name' }
  | { type: 'email'; name: string; streak: number };

const isValidEmail = (email: string) =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const emptyBoard: GameState = {
  board: [0, 0, 0, 0, 0, 0, 0, 0, 0],
  difficulty: 'easy',
  duration: 0,
  isGameOver: false,
};

export const GameScreen = ({ onLeaderboard }: Props) => {
  const [state, setState] = useState<GameState>(emptyBoard);
  const [modal, setModal] = useState<ModalState | null>(null);
  const mountedRef = useRef(true);

  useEffect(() => () => { mountedRef.current = false; }, []);

  const resetGame = useCallback(async () => {
    setModal(null);
    setState(await NativeGame.newGame());
  }, []);

  useEffect(() => {
    let isMounted = true;
    NativeGame.newGame().then((s: GameState) => { if (isMounted) setState(s); });
    return () => { isMounted = false; };
  }, []);

  const handleCellPress = useCallback(async (row: number, col: number) => {
    const newState = await NativeGame.playTurn(row, col);
    setState(newState);
    if (newState.result) {
      setModal({ type: 'name' });
    }
  }, []);

  const handleDifficultyChange = useCallback(async (diff: Difficulty) => {
    await NativeGame.setDifficulty(diff);
    setState(await NativeGame.newGame());
  }, []);

  const saveGame = async (name: string): Promise<number> => {
    const playerRes = await NativeDatabase.getPlayerId(name);
    if (playerRes.error || !playerRes.playerId) return 0;

    await NativeDatabase.saveGame(
      playerRes.playerId,
      state.result === 'win',
      state.difficulty,
      state.duration,
      new Date().toISOString(),
    );

    const streakRes = await NativeDatabase.getCurrentStreak(playerRes.playerId);
    return streakRes.streak ?? 0;
  };

  const sendToServer = async (
    email: string,
    name: string,
    streak: number,
  ): Promise<string | null> => {
    const res = await NativeNetwork.send(
      email,
      name,
      state.result === 'win',
      state.difficulty,
      state.duration,
      new Date().toISOString(),
      streak,
    );
    return res.error ?? null;
  };

  const handleNameSubmit = useCallback(
    async (name: string) => {
      const streak = await saveGame(name);
      setModal(null);
      setTimeout(() => {
        if (mountedRef.current) setModal({ type: 'email', name, streak });
      }, 300);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [state],
  );

  const handleEmailSubmit = useCallback(
    async (email: string) => {
      if (modal?.type !== 'email') return;
      const { name, streak } = modal;
      setModal(null);

      const err = await sendToServer(email, name, streak);

      setTimeout(() => {
        if (!mountedRef.current) return;
        if (err) {
          Alert.alert('Error', err, [{ text: 'OK', onPress: resetGame }]);
        } else {
          Alert.alert('Success', 'Result saved and sent!', [{ text: 'OK', onPress: resetGame }]);
        }
      }, 300);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [modal, state, resetGame],
  );

  const locked = state.board.some(c => c !== 0);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={resetGame}>
          <Text style={styles.headerButtonGreen}>New Game</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Tic-Tac-Toe (RN)</Text>
        <TouchableOpacity onPress={onLeaderboard}>
          <Text style={styles.headerButtonBlue}>Leaderboard</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        <DifficultyPicker
          value={state.difficulty}
          locked={locked}
          onChange={handleDifficultyChange}
        />

        <Board
          board={state.board}
          winningLine={state.winningLine}
          result={state.result}
          onCellPress={handleCellPress}
        />
      </View>

      {modal?.type === 'name' && (
        <InputModal
          title="Save result?"
          placeholder="Input your name"
          buttonText="Save"
          onSubmit={handleNameSubmit}
          onCancel={resetGame}
        />
      )}

      {modal?.type === 'email' && (
        <InputModal
          title="Send result to server?"
          placeholder="your@email.com"
          buttonText="Send"
          keyboardType="email-address"
          autoCapitalize="none"
          validate={isValidEmail}
          onSubmit={handleEmailSubmit}
          onCancel={resetGame}
        />
      )}
    </View>
  );
};

const difficulties: Difficulty[] = ['easy', 'medium', 'hard'];

const DifficultyPicker = ({
  value,
  locked,
  onChange,
}: {
  value: Difficulty;
  locked: boolean;
  onChange: (d: Difficulty) => Promise<void>;
}) => {
  return (
    <View style={styles.picker}>
      <Text style={styles.pickerLabel}>Difficulty:</Text>
      <View style={styles.pickerOptions}>
        {difficulties.map(d => {
          if (locked && d !== value) return null;
          const selected = d === value;
          return (
            <TouchableOpacity
              key={d}
              style={[styles.pickerOption, selected && styles.pickerOptionSelected]}
              onPress={() => onChange(d)}
              disabled={locked}
            >
              <Text style={[styles.pickerText, selected && styles.pickerTextSelected]}>
                {d.charAt(0).toUpperCase() + d.slice(1)}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const Board = ({
  board,
  winningLine,
  result,
  onCellPress,
}: {
  board: number[];
  winningLine?: { row: number; col: number }[];
  result?: GameResult;
  onCellPress: (row: number, col: number) => Promise<void>;
}) => {
  const isWinning = (r: number, c: number) =>
    winningLine?.some(cell => cell.row === r && cell.col === c) ?? false;

  const textFor = (r: GameResult) => {
    switch (r) {
      case 'win': return 'You Won!';
      case 'lose': return 'You Lost!';
      case 'draw': return "It's a Draw!";
    }
  };

  const colorFor = (r: GameResult) => {
    switch (r) {
      case 'win': return colors.success;
      case 'lose': return colors.danger;
      case 'draw': return colors.warning;
    }
  };

  return (
    <View>
      <View style={styles.board}>
        {[0, 1, 2].map(row => (
          <View key={row} style={styles.boardRow}>
            {[0, 1, 2].map(col => {
              const v = board[row * 3 + col];
              const symbol = v === 1 ? 'X' : v === -1 ? 'O' : '';
              return (
                <TouchableOpacity
                  key={col}
                  style={[styles.cell, isWinning(row, col) && styles.cellWinning]}
                  onPress={() => onCellPress(row, col)}
                  disabled={result != null || v !== 0}
                >
                  <Text style={[styles.cellText, v === 1 ? styles.cellX : styles.cellO]}>
                    {symbol}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        ))}
      </View>

      {result && (
        <View style={styles.overlay}>
          <View style={[styles.resultBadge, { backgroundColor: colorFor(result) }]}>
            <Text style={styles.resultText}>{textFor(result)}</Text>
          </View>
        </View>
      )}
    </View>
  );
}

const InputModal = ({
  title,
  placeholder,
  buttonText,
  keyboardType = 'default',
  autoCapitalize = 'sentences',
  validate,
  onSubmit,
  onCancel,
}: {
  title: string;
  placeholder: string;
  buttonText: string;
  keyboardType?: 'default' | 'email-address';
  autoCapitalize?: 'none' | 'sentences';
  validate?: (v: string) => boolean;
  onSubmit: (v: string) => Promise<void>;
  onCancel: () => Promise<void>;
}) => {
  const [value, setValue] = useState('');
  const inputRef = useRef<TextInput>(null);
  const trimmed = value.trim();
  const isValid = validate ? validate(trimmed) : trimmed.length > 0;

  useEffect(() => {
    setValue('');
    const timer = setTimeout(() => inputRef.current?.focus(), 100);
    return () => clearTimeout(timer);
  }, []);

  const handleSubmit = () => {
    if (isValid) {
      onSubmit(trimmed);
    }
  };

  return (
    <Modal visible transparent animationType="fade" onRequestClose={onCancel}>
      <TouchableWithoutFeedback onPress={onCancel}>
        <View style={styles.modalOverlay}>
          <KeyboardAvoidingView behavior="padding" style={styles.modalKeyboard}>
            <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
              <View style={styles.modalContainer}>
                <View style={styles.modalHeader}>
                  <TouchableOpacity onPress={onCancel}>
                    <Text style={styles.modalCancelText}>Cancel</Text>
                  </TouchableOpacity>
                  <Text style={styles.modalTitle}>{title}</Text>
                  <View style={styles.modalHeaderSpacer} />
                </View>
                <TextInput
                  ref={inputRef}
                  style={styles.modalInput}
                  value={value}
                  onChangeText={setValue}
                  placeholder={placeholder}
                  keyboardType={keyboardType}
                  autoCapitalize={autoCapitalize}
                  autoCorrect={false}
                  returnKeyType="done"
                  onSubmitEditing={handleSubmit}
                />
                <TouchableOpacity
                  style={[styles.modalSubmit, !isValid && styles.modalSubmitDisabled]}
                  onPress={handleSubmit}
                  disabled={!isValid}
                >
                  <Text style={styles.modalSubmitText}>{buttonText}</Text>
                </TouchableOpacity>
              </View>
            </TouchableWithoutFeedback>
          </KeyboardAvoidingView>
        </View>
      </TouchableWithoutFeedback>
    </Modal>
  );
}
