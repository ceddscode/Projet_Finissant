namespace WebApi.Services
{
    public class ClientAccessService
    {
        private readonly Dictionary<string, List<string>> _roleAllowedClients = new()
        {
            { "Citizen", new List<string> { "flutter"} },
            { "Admin", new List<string> { "web" } },
            { "White collar", new List<string> { "web" } },
            { "Blue collar", new List<string> { "flutter" } }
        };

        public bool isAllowed(IEnumerable<string> roles, string clientType)
        {
            foreach (var role in roles)
            {
                if (!_roleAllowedClients.TryGetValue(role, out var allowed) || !allowed.Contains(clientType))
                    return false;
            }

            return true;
        }
    }
}
