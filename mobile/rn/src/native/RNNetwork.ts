import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type NetworkResult = {
  error?: string
}

export interface Spec extends TurboModule {
  configure(url: string): Promise<NetworkResult>
  send(
    email: string,
    playerName: string,
    won: boolean,
    difficulty: string,
    duration: number,
    playedAt: string,
    streak: number
  ): Promise<NetworkResult>
}

export default TurboModuleRegistry.getEnforcing<Spec>('Network')
