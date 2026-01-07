import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type Difficulty = 'easy' | 'medium' | 'hard'

export type GameState = {
  board: number[]
  currentPlayer: number
  result: string
  winner?: number
  isGameOver: boolean
  isHumanTurn: boolean
  isComputerTurn: boolean
  turnCount: number
  difficulty: string
  humanPlayer: number
  computerPlayer: number
  winningLine?: { row: number; col: number }[]
  startedAt: number
  duration: number
  outcome?: string
}

export type TurnResult = {
  error?: string
  state?: GameState
  difficulty?: string
}

export interface Spec extends TurboModule {
  newGame(): Promise<TurnResult>
  setDifficulty(difficulty: string): Promise<TurnResult>
  playTurn(row: number, col: number): Promise<TurnResult>
  getState(): Promise<TurnResult>
}

export default TurboModuleRegistry.getEnforcing<Spec>('Game')
