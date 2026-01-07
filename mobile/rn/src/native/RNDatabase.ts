import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type Player = {
  id: number
  name: string
  email: string
}

export type Streak = {
  winsCount: number
  startedAt: string
}

export type LeaderboardEntry = {
  name: string
  bestStreak: number
  total: number
  wins: number
}

export type DBResult = {
  error?: string
  player?: Player | null
  streak?: Streak | null
  leaderboard?: LeaderboardEntry[]
}

export interface Spec extends TurboModule {
  getPlayer(name: string, email: string): Promise<DBResult>
  saveGame(playerId: number, won: boolean, difficulty: string, duration: number, playedAt: string): Promise<DBResult>
  getCurrentStreak(playerId: number): Promise<DBResult>
  getLeaderboard(): Promise<DBResult>
}

export default TurboModuleRegistry.getEnforcing<Spec>('Database')
