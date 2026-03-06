using System.Security.Claims;
using DocumentFormat.OpenXml.Spreadsheet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Models.Models;
using Models.Models.DTOs;

using WebApi.Interfaces;
using WebApi.Services;

namespace WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;
        private readonly UserManager<User> _userManager;
        private readonly CitizenService _citizenService;
        private readonly IIncidentService _incidentService;



        public AdminController(IAdminService adminService, UserManager<User> userManager, CitizenService citizenService, IIncidentService incidentService)
        {
            _adminService = adminService;
            _userManager = userManager;
            _citizenService = citizenService;
            _incidentService = incidentService;
        }
        [Authorize(Roles = "Admin")]

        [HttpGet("User-list")]
        public async Task<ActionResult<IEnumerable<UserListDto>>> GetUsers()
        {
            try
            {
                var users = await _adminService.GetUsers();

                if (users == null || !users.Any())
                    return NoContent(); // 204

                return Ok(users);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur serveur : {ex.Message}");
            }
        }

        [Authorize(Roles = "Admin")]
        [HttpPatch("user/{id}")]
        public async Task<ActionResult<UserListDto>> EditUser(string id, [FromBody] EditUserDto dto)
        {

            var user = await _userManager.FindByIdAsync(id);

            if (string.IsNullOrWhiteSpace(id))
                return BadRequest("User ID invalide.");

            if (dto == null)
                return BadRequest("Données manquantes.");

            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (!string.IsNullOrWhiteSpace(dto.Role))
            {
                await _adminService.UpdateUserRoleAsync(user, dto.Role);
            }


            try
            {
                var updatedUser = await _adminService.EditUserAsync(id, dto);

                if (updatedUser == null)
                    return NotFound("Utilisateur introuvable.");

                return Ok(updatedUser);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, "Erreur serveur.");
            }
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("{id}/details")]
        public async Task<ActionResult<EditUserDto>> GetUser(string id)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(id))
                    return BadRequest("User ID invalide.");

                var user = await _adminService.GetUser(id);

                if (user == null)
                    return NotFound("Utilisateur introuvable.");

                return Ok(user);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur serveur : {ex.Message}");
            }
        }


        [HttpPost("AllSortedIncidents")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<ActionResult<PagedResult<SortedIncidentsDTO>>> GetAllIncidents([FromBody] QueryParametersDTO filter)
        {
            var user = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (user == null)
            {
                return Unauthorized();
            }

            var result = await _incidentService.GetSortedIncidents(filter, true);

            return Ok(result);
        }
    }
}
