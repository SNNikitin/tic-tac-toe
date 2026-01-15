import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type LeaderboardEntry = {
  name: string
  bestStreak: number
  streakDuration: number
  total: number
  wins: number
}

export type BestStreak = {
  count: number
  startDate?: string
  endDate?: string
}

export type DBResult = {
  error?: string
  playerId?: number
  streak?: number
  leaderboard?: LeaderboardEntry[]
} & Partial<BestStreak>

export interface Spec extends TurboModule {
  getPlayerId(name: string): Promise<DBResult>
  saveGame(playerId: number, won: boolean, difficulty: string, duration: number, playedAt: string): Promise<DBResult>
  getCurrentStreak(playerId: number): Promise<DBResult>
  getBestStreak(playerId: number): Promise<DBResult>
  getLeaderboard(): Promise<DBResult>
}

export default TurboModuleRegistry.get<Spec>('NativeDatabase')
