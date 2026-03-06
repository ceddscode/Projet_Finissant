using Models.Models;
using Models.Models.DTOs;

public interface IAdminService
{
    Task<List<UserListDto>> GetUsers();
    Task<UserListDto?> EditUserAsync(string id, EditUserDto dto);
    Task<EditUserDto?> GetUser(string id);
    Task UpdateUserRoleAsync(User user, string newRole);
}
