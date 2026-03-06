namespace WebApi.Interfaces
{
    public interface IUserConnectionTracker
    {
        void AddConnection(string userId, string connectionId);
        void RemoveConnection(string userId, string connectionId);
        bool IsOnline(string userId);
        IEnumerable<string> GetConnections(string userId);
        void AddRoom(string userId, string roomId);
        void RemoveRoom(string userId, string roomId);
        bool IsInRoom(string userId, string roomId);
    }
}