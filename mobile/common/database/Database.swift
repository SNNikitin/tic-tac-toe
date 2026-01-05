import Foundation
import SQLite3

public actor GameDatabase {
    private let db: OpaquePointer?

    private init(_ db: OpaquePointer?) {
        self.db = db
    }

    deinit {
        sqlite3_close(db)
    }

    public static func open() async -> GameDatabase? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[Database] Cannot find documents directory")
            return nil
        }

        var pointer: OpaquePointer?
        let path = documentsURL.appendingPathComponent("tictactoe.sqlite").path

        if sqlite3_open(path, &pointer) != SQLITE_OK {
            print("[Database] Cannot open database at \(path)")
            return nil
        }

        let database = GameDatabase(pointer)
        await database.createTables()
        return database
    }

    private func createTables() {
        run("""
            CREATE TABLE IF NOT EXISTS players (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE
            )
        """)
        run("""
            CREATE TABLE IF NOT EXISTS games (
                player_id INTEGER NOT NULL,
                won INTEGER NOT NULL,
                difficulty TEXT NOT NULL,
                duration INTEGER NOT NULL,
                played_at TEXT NOT NULL
            )
        """)
        run("""
            CREATE TABLE IF NOT EXISTS streaks (
                player_id INTEGER NOT NULL,
                wins_count INTEGER NOT NULL,
                started_at TEXT NOT NULL,
                ended_at TEXT
            )
        """)
    }

    public func getPlayer(name: String, email: String) -> (id: UInt, name: String, email: String)? {
        var player: (id: UInt, name: String, email: String)?
        fetch("""
            INSERT INTO players (name, email) VALUES (?, ?)
            ON CONFLICT(email) DO UPDATE SET name = excluded.name
            RETURNING id, name, email
        """, params: [name, email]) { statement in
            player = (
                id: UInt(sqlite3_column_int64(statement, 0)),
                name: String(cString: sqlite3_column_text(statement, 1)),
                email: String(cString: sqlite3_column_text(statement, 2))
            )
        }
        return player
    }

    public func saveGame(playerId: UInt, won: Int, difficulty: String, duration: Int, playedAt: String) {
        run("INSERT INTO games (player_id, won, difficulty, duration, played_at) VALUES (?, ?, ?, ?, ?)",
            params: [playerId, won, difficulty, duration, playedAt])

        if won == 1 {
            run("UPDATE streaks SET wins_count = wins_count + 1 WHERE player_id = ? AND ended_at IS NULL",
                params: [playerId])
            run("""
                INSERT INTO streaks (player_id, wins_count, started_at)
                SELECT ?, 1, ? WHERE NOT EXISTS (
                    SELECT 1 FROM streaks WHERE player_id = ? AND ended_at IS NULL
                )
            """, params: [playerId, playedAt, playerId])
        } else {
            run("UPDATE streaks SET ended_at = ? WHERE player_id = ? AND ended_at IS NULL",
                params: [playedAt, playerId])
        }
    }

    public func getCurrentStreak(for playerId: UInt) -> (winsCount: Int, startedAt: String)? {
        var streak: (winsCount: Int, startedAt: String)?
        fetch("SELECT wins_count, started_at FROM streaks WHERE player_id = ? AND ended_at IS NULL",
              params: [playerId]) { statement in
            streak = (
                winsCount: Int(sqlite3_column_int(statement, 0)),
                startedAt: String(cString: sqlite3_column_text(statement, 1))
            )
        }
        return streak
    }

    public func getLeaderboard() -> [(name: String, bestStreak: Int, total: Int, wins: Int)] {
        var entries = [(name: String, bestStreak: Int, total: Int, wins: Int)]()
        fetch("""
            SELECT p.name, best, total, wins
            FROM (
                SELECT s.player_id, MAX(s.wins_count) as best, COUNT(g.won) as total, SUM(g.won) as wins
                FROM streaks s LEFT JOIN games g ON g.player_id = s.player_id
                GROUP BY s.player_id
            ) sub JOIN players p ON p.id = sub.player_id
            ORDER BY best DESC, wins DESC
        """) { statement in
            entries.append((
                name: String(cString: sqlite3_column_text(statement, 0)),
                bestStreak: Int(sqlite3_column_int(statement, 1)),
                total: Int(sqlite3_column_int(statement, 2)),
                wins: Int(sqlite3_column_int(statement, 3))
            ))
        }
        return entries
    }

    private func run(_ sql: String, params: [Any] = []) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("[Database] SQL prepare error: \(errorMessage)")
            return
        }
        defer { sqlite3_finalize(statement) }
        bind(statement, params)
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE && result != SQLITE_ROW {
            print("[Database] SQL step error: \(errorMessage)")
        }
    }

    private func fetch(_ sql: String, params: [Any] = [], handler: (OpaquePointer) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("[Database] SQL prepare error: \(errorMessage)")
            return
        }
        defer { sqlite3_finalize(statement) }
        bind(statement, params)
        while sqlite3_step(statement) == SQLITE_ROW { handler(statement!) }
    }

    private var errorMessage: String {
        String(cString: sqlite3_errmsg(db))
    }

    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private func bind(_ statement: OpaquePointer?, _ params: [Any]) {
        for (position, param) in params.enumerated() {
            let index = Int32(position + 1)
            switch param {
                case let value as String: sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
                case let value as Int: sqlite3_bind_int(statement, index, Int32(value))
                case let value as UInt: sqlite3_bind_int64(statement, index, Int64(value))
                case let value as Double: sqlite3_bind_double(statement, index, value)
                default: break
            }
        }
    }
}
