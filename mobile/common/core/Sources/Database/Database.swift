import Foundation
import SQLite3

public actor GameDatabase {
    private nonisolated(unsafe) let db: OpaquePointer?

    private init(_ db: OpaquePointer?) {
        self.db = db
    }

    deinit {
        sqlite3_close(db)
    }

    public nonisolated static func open() -> GameDatabase? {
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
        database.createTables()
        return database
    }

    private nonisolated func createTables() {
        run("""
            CREATE TABLE IF NOT EXISTS players (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            )
        """)
        run("""
            CREATE TABLE IF NOT EXISTS games (
                player_id INTEGER NOT NULL,
                won BOOLEAN NOT NULL,
                difficulty TEXT NOT NULL,
                duration INTEGER NOT NULL,
                played_at TEXT NOT NULL
            )
        """)
    }

    public func getPlayerId(name: String) -> UInt? {
        var playerId: UInt?
        fetch("""
            INSERT INTO players (name) VALUES (?)
            ON CONFLICT(name) DO UPDATE SET name = excluded.name
            RETURNING id
        """, params: [name]) { statement in
            playerId = UInt(sqlite3_column_int64(statement, 0))
        }
        return playerId
    }

    public func saveGame(playerId: UInt, won: Bool, difficulty: String, duration: Int, playedAt: String) {
        run("INSERT INTO games (player_id, won, difficulty, duration, played_at) VALUES (?, ?, ?, ?, ?)",
            params: [playerId, won ? 1 : 0, difficulty, duration, playedAt])
    }

    public func getCurrentStreak(for playerId: UInt) -> Int {
        var count = 0
        fetch("""
            WITH last_loss AS (
                SELECT MAX(played_at) as lost_at FROM games WHERE player_id = ? AND won = 0
            )
            SELECT COUNT(*)
            FROM games
            WHERE player_id = ? AND won = 1
              AND played_at > COALESCE((SELECT lost_at FROM last_loss), '')
        """, params: [playerId, playerId]) { statement in
            count = Int(sqlite3_column_int(statement, 0))
        }
        return count
    }

    public func getBestStreak(for playerId: UInt) -> (count: Int, startDate: String, endDate: String)? {
        var result: (count: Int, startDate: String, endDate: String)?
        fetch("""
            WITH numbered AS (
                SELECT won, played_at,
                       SUM(CASE WHEN won = 0 THEN 1 ELSE 0 END) OVER (ORDER BY played_at) as grp
                FROM games WHERE player_id = ?
            ),
            streaks AS (
                SELECT COUNT(*) as len,
                       MIN(played_at) as started,
                       MAX(played_at) as ended
                FROM numbered WHERE won = 1
                GROUP BY grp
            )
            SELECT len, started, ended
            FROM streaks
            ORDER BY len DESC
            LIMIT 1
        """, params: [playerId]) { statement in
            result = (
                count: Int(sqlite3_column_int(statement, 0)),
                startDate: self.columnText(statement, 1),
                endDate: self.columnText(statement, 2)
            )
        }
        return result
    }

    public func getLeaderboard() -> [(name: String, bestStreak: Int, streakDuration: Int, total: Int, wins: Int)] {
        var entries = [(name: String, bestStreak: Int, streakDuration: Int, total: Int, wins: Int)]()
        fetch("""
            WITH numbered AS (
                SELECT player_id, won, played_at, duration,
                       SUM(CASE WHEN won = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY player_id ORDER BY played_at) as grp
                FROM games
            ),
            streaks AS (
                SELECT player_id,
                       COUNT(*) as len,
                       MIN(played_at) as started,
                       MAX(played_at || '|' || duration) as last_info
                FROM numbered WHERE won = 1
                GROUP BY player_id, grp
            ),
            best AS (
                SELECT player_id, len, started,
                       SUBSTR(last_info, 1, INSTR(last_info, '|') - 1) as last_win_at,
                       CAST(SUBSTR(last_info, INSTR(last_info, '|') + 1) AS INTEGER) as last_duration,
                       ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY len DESC) as rn
                FROM streaks
            )
            SELECT p.name,
                   COALESCE(b.len, 0),
                   COALESCE(CAST((julianday(b.last_win_at) - julianday(b.started)) * 86400 + b.last_duration / 1000 AS INTEGER), 0),
                   (SELECT COUNT(*) FROM games WHERE player_id = p.id),
                   (SELECT COALESCE(SUM(won), 0) FROM games WHERE player_id = p.id)
            FROM players p
            LEFT JOIN best b ON b.player_id = p.id AND b.rn = 1
            WHERE EXISTS (SELECT 1 FROM games WHERE player_id = p.id)
            ORDER BY 2 DESC, 5 DESC
        """) { statement in
            entries.append((
                name: self.columnText(statement, 0),
                bestStreak: Int(sqlite3_column_int(statement, 1)),
                streakDuration: Int(sqlite3_column_int(statement, 2)),
                total: Int(sqlite3_column_int(statement, 3)),
                wins: Int(sqlite3_column_int(statement, 4))
            ))
        }
        return entries
    }

    private nonisolated func run(_ sql: String, params: [Any] = []) {
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

    private nonisolated func fetch(_ sql: String, params: [Any] = [], handler: (OpaquePointer) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("[Database] SQL prepare error: \(errorMessage)")
            return
        }
        defer { sqlite3_finalize(statement) }
        bind(statement, params)
        guard let stmt = statement else { return }
        while sqlite3_step(stmt) == SQLITE_ROW { handler(stmt) }
    }

    private nonisolated func columnText(_ statement: OpaquePointer, _ index: Int32) -> String {
        guard let ptr = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: ptr)
    }

    private nonisolated var errorMessage: String {
        String(cString: sqlite3_errmsg(db))
    }

    private nonisolated(unsafe) let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private nonisolated func bind(_ statement: OpaquePointer?, _ params: [Any]) {
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
