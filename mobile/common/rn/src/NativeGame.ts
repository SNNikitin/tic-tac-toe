import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type Difficulty = 'easy' | 'medium' | 'hard'

export type GameState = {
  board: number[]
  isHumanTurn: boolean
  difficulty: Difficulty
  winningLine?: { row: number; col: number }[]
  duration: number
  humanWon: boolean
}

export interface Spec extends TurboModule {
  newGame(): Promise<GameState>
  setDifficulty(difficulty: Difficulty): Promise<GameState>
  playTurn(row: number, col: number): Promise<GameState>
}

export default TurboModuleRegistry.get<Spec>('NativeGame')
