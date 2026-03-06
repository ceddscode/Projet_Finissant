using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.DTOs;
using municipaligo_serveur.Data;

namespace WebApi.Services
{

    public class AdminService : IAdminService
    {
        private readonly UserManager<User> _userManager;
        private ApplicationDbContext _context;

        

        public AdminService(ApplicationDbContext context, UserManager<User> userManager)
        {

            _context = context;
            _userManager = userManager;
        }

        public async Task<List<UserListDto>> GetUsers()
        {
            if (_userManager == null)
                throw new InvalidOperationException("UserManager is not initialized.");

            var users = await _userManager.Users.ToListAsync();

            if (users == null || !users.Any())
                return new List<UserListDto>();

            var result = new List<UserListDto>();

            foreach (var user in users)
            {

                var roles = await _userManager.GetRolesAsync(user);
                var role = roles?.FirstOrDefault() ?? "Citizen";

                Citizen? citizen = null;

                if (role != "Admin")
                {
                    citizen = await _context.Citizens
                        .FirstOrDefaultAsync(c => c.UserId == user.Id);
                }

                result.Add(new UserListDto
                {
                    Id = user.Id,
                    FirstName = citizen?.FirstName,
                    LastName = citizen?.LastName,
                    Email = user.Email ?? "",
                    Role = role,
                    IsAdmin = role == "Admin"
                });
            }

            return result;
        }

        
        public async Task<UserListDto?> EditUserAsync(string userId, EditUserDto dto)
        {
            if (string.IsNullOrWhiteSpace(userId))
                throw new ArgumentException("UserId is required");

            if (dto == null)
                throw new ArgumentNullException(nameof(dto));

            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
                return null;

            // 🔹 Update Email
            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                user.Email = dto.Email;
                user.UserName = dto.Email;

                var updateResult = await _userManager.UpdateAsync(user);

                if (!updateResult.Succeeded)
                    throw new Exception("Failed to update email.");
            }

            // 🔹 Update Role (méthode séparée)
            if (!string.IsNullOrWhiteSpace(dto.Role))
            {
                await UpdateUserRoleAsync(user, dto.Role);
            }

            // 🔹 Get current role
            var roles = await _userManager.GetRolesAsync(user);
            var role = roles?.FirstOrDefault() ?? "Citizen";

            Citizen? citizen = null;

            if (role != "Admin")
            {
                citizen = await _context.Citizens
                    .FirstOrDefaultAsync(c => c.UserId == user.Id);

                if (citizen == null)
                {
                    citizen = new Citizen { UserId = user.Id };
                    _context.Citizens.Add(citizen);
                }

                // Update partiel
                citizen.FirstName = dto.FirstName ?? citizen.FirstName;
                citizen.LastName = dto.LastName ?? citizen.LastName;
                citizen.RoadName = dto.RoadName ?? citizen.RoadName;
                citizen.PostalCode = dto.PostalCode ?? citizen.PostalCode;
                citizen.City = dto.City ?? citizen.City;

                if (dto.RoadNumber.HasValue)
                    citizen.RoadNumber = dto.RoadNumber.Value;

                if (!string.IsNullOrWhiteSpace(dto.PhoneNumber))
                    user.PhoneNumber = dto.PhoneNumber;
            }

            await _context.SaveChangesAsync();

            return new UserListDto
            {
                Id = user.Id,
                Email = user.Email ?? "",
                Role = role,
                IsAdmin = role == "Admin",
                FirstName = citizen?.FirstName,
                LastName = citizen?.LastName
            };
        }

        public async Task UpdateUserRoleAsync(User user, string newRole)
        {
            var allowedRoles = new[] { "Admin", "Citizen", "Blue collar", "White collar" };

            if (!allowedRoles.Contains(newRole))
                throw new ArgumentException("Invalid role");

            var currentRoles = await _userManager.GetRolesAsync(user);

            if (currentRoles == null)
                throw new Exception("User roles not found.");

            if (!currentRoles.Contains(newRole))
            {
                var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
                if (!removeResult.Succeeded)
                    throw new Exception("Failed to remove current roles.");

                var addResult = await _userManager.AddToRoleAsync(user, newRole);
                if (!addResult.Succeeded)
                    throw new Exception("Failed to add new role.");
            }
        }

        public async Task<EditUserDto?> GetUser(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId))
                throw new ArgumentException("UserId is required");

            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
                return null;

            var roles = await _userManager.GetRolesAsync(user);
            var role = roles?.FirstOrDefault() ?? "Citizen";

            var citizen = await _context.Citizens
                .FirstOrDefaultAsync(c => c.UserId == userId);

            return new EditUserDto
            {
                Id = user.Id,
                Email = user.Email,
                Role = role,
                FirstName = citizen?.FirstName,
                LastName = citizen?.LastName,
                PhoneNumber = user.PhoneNumber,
                RoadNumber = citizen?.RoadNumber ?? 0,
                RoadName = citizen?.RoadName,
                PostalCode = citizen?.PostalCode,
                City = citizen?.City
            };
        }



    }
}
