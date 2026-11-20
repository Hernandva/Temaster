import Foundation

/// The game's turns: each of `playlists` has its own queue, and the rounds go from one playlist to the next, so with
/// one playlist per generation every generation plays in turn. With a single playlist the turn never changes.
extension GameViewData {
    /// The playlist the current round plays: everyone's, or the one of the generation whose turn it is.
    var currentPlaylist: Playlist? {
        playlists.indices.contains(turn) ? playlists[turn] : nil
    }

    /// The song that is playing: the first of the turn's queue. `nil` until the songs load.
    var currentSong: Song? {
        currentQueue?.first
    }

    /// Songs left of the turn's playlist, or `nil` until they load.
    private var currentQueue: [Song]? {
        guard let queues, queues.indices.contains(turn) else { return nil }
        return queues[turn]
    }

    /// Takes the current song out of the game for good.
    mutating func removeCurrentSong() {
        guard currentSong != nil else { return }
        queues?[turn].removeFirst()
    }

    /// Sends the current song to the end of the turn's queue, so the next one becomes the current song.
    mutating func moveCurrentSongToEnd() {
        guard var queue = currentQueue, !queue.isEmpty else { return }
        queue.append(queue.removeFirst())
        queues?[turn] = queue
    }

    /// Gives the turn to the next playlist, in order and starting over after the last one, that has songs left; it
    /// stays with the current one only when that is the only one left. Returns `false` when none has songs left.
    mutating func passTurn() -> Bool {
        guard let queues, !queues.isEmpty else { return false }
        let order = (1...queues.count).map { (turn + $0) % queues.count }
        guard let next = order.first(where: { !queues[$0].isEmpty }) else { return false }
        turn = next
        return true
    }
}
