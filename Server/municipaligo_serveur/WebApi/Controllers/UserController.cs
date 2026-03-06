using System.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;
using municipaligo_serveur.Data;
using WebApi.Services;

namespace WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly ApplicationDbContext _db;
        private readonly IConfiguration _config;
        private readonly ClientAccessService _clientAccessService;
        private readonly BadgeService _badgeService;
        public UserController(UserManager<User> userManager, ApplicationDbContext db, IConfiguration config, ClientAccessService clientAccessService, BadgeService badgeService)
        {
            _userManager = userManager;
            _db = db;
            _config = config;
            _clientAccessService = clientAccessService;
            _badgeService = badgeService;
        }
        string? CurrentUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier);

        protected string GetClientType()
        {
            return Request.Headers["X-Client-Type"].FirstOrDefault() ?? "unknown";
        }

        private ActionResult ValidationProblemResult()
        {
            var errors = ModelState
                .Where(x => x.Value != null && x.Value.Errors.Count > 0)
                .SelectMany(x => x.Value!.Errors.Select(e =>
                {
                    var raw = e.ErrorMessage ?? "";
                    var parts = raw.Split('|', 2);
                    return new
                    {
                        field = x.Key,
                        code = parts.Length > 0 ? parts[0] : "ERR_VALIDATION",
                        message = parts.Length > 1 ? parts[1] : raw
                    };
                }))
                .ToList();

            return BadRequest(new { errors });
        }

        [Authorize(Roles = "Blue collar,Citizen")]
        [HttpPost("me/change-password")]
        public async Task<IActionResult> ChangeMyPassword([FromBody] ChangePasswordDTO dto)
        {
            if (!ModelState.IsValid) return ValidationProblemResult();
            var me = CurrentUserId();
            if (me == null) return Unauthorized();

            if (dto.NewPassword != dto.ConfirmNewPassword)
                return BadRequest(new { message = "Passwords do not match" });

            var user = await _userManager.FindByIdAsync(me);
            if (user == null) return NotFound();

            var res = await _userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);
            if (!res.Succeeded)
                return BadRequest(new
                {
                    errors = res.Errors.Select(e => new { e.Code, e.Description })
                });
            return Ok(new { message = "OK" });
        }

        [Authorize(Roles = "Blue collar,Citizen")]
        [HttpGet("me")]
        public async Task<ActionResult<UserMeDto>> GetMe()
        {
            var me = CurrentUserId();
            if (me == null) return Unauthorized();

            var user = await _userManager.FindByIdAsync(me);
            if (user == null) return NotFound();

            var citizen = await _db.Citizens.FirstOrDefaultAsync(c => c.UserId == me);

            return Ok(new UserMeDto
            {
                Id = user.Id,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                FirstName = citizen?.FirstName,
                LastName = citizen?.LastName,
                RoadNumber = citizen?.RoadNumber ?? 0,
                RoadName = citizen?.RoadName,
                PostalCode = citizen?.PostalCode,
                City = citizen?.City,
                Points= citizen?.Points,
                IsAnonymous = user.IsAnonymous
            });
        }

        [Authorize]
        [HttpGet("me/badges")]
        public async Task<IActionResult> GetMyBadges()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
                return Unauthorized();

            var result = await _badgeService.GetCitizenBadgeProfile(userId);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        [Authorize(Roles = "Blue collar,Citizen")]
        [HttpPatch("me")]
        public async Task<ActionResult<UserMeDto>> PatchMe([FromBody] UpdateMeDto dto)
        {
            var me = CurrentUserId();
            if (me == null) return Unauthorized();

            var user = await _userManager.FindByIdAsync(me);
            if (user == null) return NotFound();

            var identityChanged = false;

            if (!string.IsNullOrWhiteSpace(dto.Email) && dto.Email != user.Email)
            {
                user.Email = dto.Email.Trim();
                user.UserName = dto.Email.Trim();
                identityChanged = true;
            }

            if (!string.IsNullOrWhiteSpace(dto.PhoneNumber) && dto.PhoneNumber != user.PhoneNumber)
            {
                user.PhoneNumber = dto.PhoneNumber.Trim();
                identityChanged = true;
            }

            if (dto.IsAnonymous != null && dto.IsAnonymous != user.IsAnonymous)
            {
                user.IsAnonymous = (bool)dto.IsAnonymous;
                identityChanged = true;
            }

            if (identityChanged)
            {
                var res = await _userManager.UpdateAsync(user);
                if (!res.Succeeded) return BadRequest(res.Errors.Select(e => e.Description));
            }

            var citizen = await _db.Citizens.FirstOrDefaultAsync(c => c.UserId == me);
            if (citizen == null)
            {
                citizen = new Citizen { UserId = me };
                _db.Citizens.Add(citizen);
            }

            if (dto.FirstName != null) citizen.FirstName = dto.FirstName;
            if (dto.LastName != null) citizen.LastName = dto.LastName;
            if (dto.RoadName != null) citizen.RoadName = dto.RoadName;
            if (dto.PostalCode != null) citizen.PostalCode = dto.PostalCode;
            if (dto.City != null) citizen.City = dto.City;
            if (dto.RoadNumber.HasValue) citizen.RoadNumber = dto.RoadNumber.Value;

            await _db.SaveChangesAsync();

            return Ok(new UserMeDto
            {
                Id = user.Id,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                FirstName = citizen.FirstName,
                LastName = citizen.LastName,
                RoadNumber = citizen.RoadNumber,
                RoadName = citizen.RoadName,
                PostalCode = citizen.PostalCode,
                City = citizen.City,
                Points = citizen?.Points
            });
        }


        [HttpPost("Register")]
        public async Task<ActionResult> Register([FromBody] RegisterDTO register)
        {
            if (!ModelState.IsValid) return ValidationProblemResult();

            if (register.Password != register.PasswordConfirm)
            {
                return BadRequest(new { Message = "Les deux mots de passe spécifiés sont différents." });
            }

            var user = new User
            {
                UserName = register.Email,
                Email = register.Email,
                PhoneNumber = register.PhoneNumber,
                IsAnonymous = true                
            };

            var identityResult = await _userManager.CreateAsync(user, register.Password);

            if (!identityResult.Succeeded)
            {
                return BadRequest(new
                {
                    Message = "La création de l'utilisateur a échoué.",
                    Errors = identityResult.Errors.Select(e => e.Description)
                });
            }

            await _userManager.AddToRoleAsync(user, "Citizen");

            var citizen = new Citizen
            {
                UserId = user.Id,
                FirstName = register.FirstName,
                LastName = register.LastName,
                RoadNumber = register.RoadNumber,
                RoadName = register.RoadName,
                PostalCode = register.PostalCode,
                City = register.City,
                Taches = new List<Incident>(),
                Points = 0
            };

            _db.Citizens.Add(citizen);
            await _db.SaveChangesAsync();
            var baseBadge = await _db.Badges.FirstOrDefaultAsync(b => b.Id == 1);

            if (baseBadge != null)
            {
                _db.CitizenBadges.Add(new CitizenBadge
                {
                    CitizenId = citizen.Id,
                    BadgeId = baseBadge.Id,
                    EarnedAt = DateTime.UtcNow
                });

                citizen.Points += baseBadge.MinPointsRequired;

                await _db.SaveChangesAsync();
            }
            return Ok(new { Message = "Inscription réussie !" });
        }


        [HttpPost("Login")]
        [AllowAnonymous]
        public async Task<ActionResult> Login(LoginDTO login)
        {
            if (!ModelState.IsValid) return ValidationProblemResult();
            var user = await _userManager.FindByEmailAsync(login.Username);

            if (user == null || !await _userManager.CheckPasswordAsync(user, login.Password))
                return BadRequest(new { Message = "Le nom d'utilisateur ou le mot de passe est invalide." });

            var roles = await _userManager.GetRolesAsync(user);
            

            var clientType = GetClientType();

            if (!_clientAccessService.isAllowed(roles, clientType) || clientType == "unknown")
                return Unauthorized(new { Message = $"Accès refusé pour ce rôle depuis {clientType}" });

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.UserName ?? ""),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));
            claims.Add(new Claim("role", roles.FirstOrDefault() ?? ""));

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(int.Parse(_config["Jwt:ExpiresMinutes"])),
                signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                token = new JwtSecurityTokenHandler().WriteToken(token),
                validTo = token.ValidTo,
            });
        }
    }
}
