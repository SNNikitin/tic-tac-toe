import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type Difficulty = 'easy' | 'medium' | 'hard'
export type GameResult = 'win' | 'lose' | 'draw'

export type GameState = {
  board: number[]
  difficulty: Difficulty
  duration: number
  isGameOver: boolean
  result?: GameResult
  winningLine?: { row: number; col: number }[]
}

export interface Spec extends TurboModule {
  newGame(): Promise<GameState>
  setDifficulty(difficulty: Difficulty): Promise<GameState>
  playTurn(row: number, col: number): Promise<GameState>
}

export default TurboModuleRegistry.get<Spec>('NativeGame')
