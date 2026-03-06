using System.Collections.Concurrent;
using WebApi.Interfaces;

namespace WebApi.Services
{
    public class UserConnectionTracker : IUserConnectionTracker
    {
        private readonly ConcurrentDictionary<string, HashSet<string>> _connections = new();
        private readonly object _lock = new();

        public void AddConnection(string userId, string connectionId)
        {
            lock (_lock)
            {
                _connections.AddOrUpdate(
                    userId,
                    _ => [connectionId],
                    (_, connections) => { connections.Add(connectionId); return connections; }
                );
            }
        }

        public void RemoveConnection(string userId, string connectionId)
        {
            lock (_lock)
            {
                if (_connections.TryGetValue(userId, out var connections))
                {
                    connections.Remove(connectionId);
                    if (connections.Count == 0)
                        _connections.TryRemove(userId, out _);
                }
            }
        }

        private readonly ConcurrentDictionary<string, HashSet<string>> _rooms = new();

        public void AddRoom(string userId, string roomId)
        {
            _rooms.GetOrAdd(userId, _ => new HashSet<string>()).Add(roomId);
        }

        public void RemoveRoom(string userId, string roomId)
        {
            if (_rooms.TryGetValue(userId, out var rooms))
                rooms.Remove(roomId);
        }

        public bool IsInRoom(string userId, string roomId)
        {
            return _rooms.TryGetValue(userId, out var rooms) && rooms.Contains(roomId);
        }

        public bool IsOnline(string userId) => _connections.ContainsKey(userId);

        public IEnumerable<string> GetConnections(string userId) =>
            _connections.TryGetValue(userId, out var connections)
                ? connections
                : Enumerable.Empty<string>();
    }
}