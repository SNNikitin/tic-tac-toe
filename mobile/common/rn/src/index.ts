import NativeGameModule from './NativeGame'
import NativeDatabaseModule from './NativeDatabase'
import NativeNetworkModule from './NativeNetwork'

export type { GameState, Difficulty } from './NativeGame'
export type { LeaderboardEntry } from './NativeDatabase'

const notSupported = () => Promise.reject(new Error('Not supported on this platform'))

const stub = { newGame: notSupported, setDifficulty: notSupported, playTurn: notSupported,
  getPlayerId: notSupported, saveGame: notSupported, getCurrentStreak: notSupported, getBestStreak: notSupported, getLeaderboard: notSupported,
  configure: notSupported, send: notSupported }

export const NativeGame = NativeGameModule ?? stub
export const NativeDatabase = NativeDatabaseModule ?? stub
export const NativeNetwork = NativeNetworkModule ?? stub
