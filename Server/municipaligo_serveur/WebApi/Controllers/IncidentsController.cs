using System.Collections.Generic;
using System.Collections.Immutable;
using System.Reflection.Metadata.Ecma335;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.CodeAnalysis;
using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;
using WebApi.Interfaces;
using WebApi.Services;

namespace WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class IncidentsController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly CitizenService _citizenService;
        private readonly IIncidentService _incidentService;


        public IncidentsController(IIncidentService incidentService, UserManager<User> userManager, CitizenService citizenService)
        {
            _incidentService = incidentService;
            _userManager = userManager;
            _citizenService = citizenService;
        }

        [HttpGet("All")]
        public async Task<ActionResult<IEnumerable<IncidentListDTO>>> GetAllIncidents()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return await _incidentService.GetAllIncidents(userId);
        }
        [HttpPost("Not-Validated")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<ActionResult<PagedResult<SortedIncidentsDTO>>> GetIncidentsNotValidated([FromBody] QueryParametersDTO filter)
        {

            
            var user = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (user == null)
                return Unauthorized();

            bool isAdmin = User.IsInRole("Admin");

            var result = await _incidentService.GetSortedNotValidatedIncidents(filter, isAdmin);

            return Ok(result);
        }

        [HttpGet("Validated")]
        public async Task<ActionResult<IEnumerable<IncidentListDTO>>> GetIncidentValidated()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return await _incidentService.GetValidatedIncidents(userId);
        }

        [HttpPost("Not-Assigned")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<ActionResult<PagedResult<SortedIncidentsDTO>>> GetIncidentsNotAssigned([FromBody] QueryParametersDTO filter)
        {
            var user = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (user == null)
                return Unauthorized();

            bool isAdmin = User.IsInRole("Admin");

            var result = await _incidentService.GetSortedNotAssignedIncidents(filter, isAdmin);

            return Ok(result);
        }

        [HttpGet("AssignedToCitizen")]
        public async Task<ActionResult<IEnumerable<Incident>>> GetIncidentsAssignedToCitizen()
        {

            return await _incidentService.GetIncidentsAssignedToCitizen();
        }

        [HttpGet("UnderRepair")]
        public async Task<ActionResult<IEnumerable<Incident>>> GetIncidentsUnderRepair()
        {

            return await _incidentService.GetIncidentsUnderRepair();
        }

        [HttpGet("Not-Confirmed")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<IncidentDetailsDTO>?>> GetIncidentsNotConfirmed()
        {
            return await _incidentService.GetIncidentsNotConfirmed();
        }

        [HttpGet("Done")]
        public async Task<ActionResult<IEnumerable<Incident>>> GetIncidentsDone()
        {

            return await _incidentService.GetIncidentsDone();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<IncidentDetailsDTO?>> GetIncidentDetails(int id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var incident = await _incidentService.GetIncidentDetails(id, userId);

            if (incident == null)
                return NotFound();

            return Ok(incident);
        }

        [HttpGet("DetailsConfirmation/{id}")]
        public async Task<ActionResult<IncidentConfirmationDetailsDTO?>> GetIncidentConfirmationDetails(int id)
        {
            var incident = await _incidentService.GetIncidentConfirmationDetails(id);

            if (incident == null)
            {
                return NotFound();
            }

            return incident;
        }

        [HttpGet("MyAssignedIncidents")]
        [Authorize]
        public async Task<ActionResult<List<IncidentListDTO>?>> GetMyAssignedIncidents()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var incidents = await _incidentService.GetMyAssignedIncidents(userId);

            return incidents;
        }

        [HttpGet("MySubbedIncidents")]
        [Authorize]
        public async Task<ActionResult<List<IncidentListDTO>>> GetSubbedIncidents()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var incidents = await _incidentService.GetMySubbedIncidents(userId);

            return Ok(incidents);
        }

        [HttpGet("IncidentHistory/{id}")]
        [Authorize]
        public async Task<ActionResult<List<IncidentHistoryDTO>>> GetIncidentHistory(int id)
        {
            List<IncidentHistoryDTO> incidentHistoriesDtos = await _incidentService.GetIncidentHistory(id);

            if(incidentHistoriesDtos == null)
            {
                return NotFound();
            }

            return Ok(incidentHistoriesDtos);
        }

        [HttpGet("MyIncidentHistory")]
        [Authorize]
        public async Task<ActionResult<List<IncidentHistoryDTO>>> GetMyIncidentHistory()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            List<IncidentHistoryDTO> incidentHistoriesDtos = await _incidentService.GetMyIncidentHistory(userId);

            if (incidentHistoriesDtos == null)
            {
                return NotFound();
            }

            return Ok(incidentHistoriesDtos);
        }

        private static string? ExtractQuartier (string? location)
        {
            if (string.IsNullOrWhiteSpace(location)) return null;

            var parts = location.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            if (parts.Length == 0) return null;

            var last = parts[^1];
            if (last.Contains("Vieux-Longueuil", StringComparison.OrdinalIgnoreCase)) return "Vieux-Longueuil";
            if (last.Contains("Saint-Hubert", StringComparison.OrdinalIgnoreCase)) return "Saint-Hubert";
            if (last.Contains("Greenfield", StringComparison.OrdinalIgnoreCase)) return "Greenfield Park";

            return null;
        }

        [HttpPost("CreateIncident")]
        [Authorize(Roles = "Blue collar, Citizen")]
        public async Task<ActionResult<Incident>> CreateIncident(ReportIncident req)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            if (user == null)
            {
                return Unauthorized();
            }

            if(req == null)
                return BadRequest();

            try
            {
                var incident = new Incident(
                    0,
                    req.Title.Trim(),
                    req.Description?.Trim(),
                    req.Location.Trim(),
                    DateTime.UtcNow,
                    null,
                    req.Category,
                    Status.WaitingForValidation,
                    null,
                    null,
                    user.Id,
                    null,
                    req.ImagesUrl ?? new List<string>(),
                    null,
                    null,
                    null,
                    req.Latitude,
                    req.Longitude,
                    0,
                    ExtractQuartier(req.Location)
                );

                await _incidentService.PostIncident(incident);

                await _incidentService.AddToHistoryAsync(
                    incident.Id,
                    InterventionType.Created,
                    user.Id
                );

                return CreatedAtAction(
                    nameof(GetIncidentDetails),
                    new { id = incident.Id },
                    incident
                );
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Erreur survenu lors de la création :" + ex.Message);
            }
        }

        [HttpPut("Edit/{id}")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<IActionResult> Edit(int id, [FromBody] EditIncidentDTO dto)
        {
            var exists = await _incidentService.IncidentExists(id);

            if (!exists)
                return NotFound();

            await _incidentService.EditIncident(id,dto);

            return Ok();
        }

        [HttpDelete("Delete/{id}")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<IActionResult> Delete(int id)
        {
            var exists = await _incidentService.IncidentExists(id);

            if (!exists)
                return NotFound();

            await _incidentService.DeleteIncidentAsync(id);

            return Ok();
        }

        [HttpPut("Assign/BlueCollar/{id}")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<IActionResult> AssignIncidentToBlueCollar(int id)
        {
            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null)
            {
                return Unauthorized();
            }

            var success = await _incidentService.AssignToBlueCollarAsync(id);

            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(id, InterventionType.AssignedToBlueCollar, user.Id);

            return Ok();
        }
        [HttpGet("Quartiers")]
        public async Task<ActionResult<List<string>>> GetQuartiers()
        {
            var quartiers = await _incidentService.GetQuartiers();
            return Ok(quartiers);
        }

        [HttpPut("Approuve/{id}")]
        
        public async Task<IActionResult> ApproveIncident(int id, [FromBody] ApproveDTO dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null)
            {
                return Unauthorized();
            }

            var success = await _incidentService.ApproveIncidentAsync(id,dto.Points);

            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(id, InterventionType.Validated, user.Id);

            return Ok();
        }

        [HttpPut("Confirm/{id}")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<IActionResult> ConfirmIncident(int id)
        {
            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null)
            {
                return Unauthorized();
            }

            var success = await _incidentService.ConfirmIncidentAsync(id);

            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(id, InterventionType.ApprovedRepair, user.Id);

            return Ok();
        }

        [HttpPut("Refuse")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<IActionResult> RefuseIncident(RefuseDTO refuseDTO)
        {
            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null)
            {
                return Unauthorized();
            }

            var success = await _incidentService.RefuseIncidentAsync(refuseDTO.IncidentId, refuseDTO.Description);

            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(refuseDTO.IncidentId, InterventionType.RefusedRepair, user.Id);

            return Ok();
        }

        [HttpPut("AssignToCitizen/{id}")]
        [Authorize(Roles = "White collar, Admin")]
        public async Task<IActionResult> AssignToCitizen(int id)
        {

            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null)
            {
                return Unauthorized();
            }

            var success = await _incidentService.AssignIncidentToCitizenAsync(id);

            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(id, InterventionType.AssignedToCitizen, user.Id);

            return Ok();
        }

        [HttpPut("Assign/take/{id}")]
        [Authorize(Roles = "Citizen")]
        public async Task<IActionResult> CitizenTakeTask(int id)
        {
            var user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null)
            {
                return Unauthorized();
            }

            var citizen = await _citizenService.GetCitizen(user.Id);

            if (citizen == null)
            {
                return Unauthorized();
            }

            var success = await _incidentService.CitizenTakeTaskAsync(id, citizen);
            
            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(id, InterventionType.TaskTookByCitizen, user.Id);

            return Ok();
        }

        [HttpPut("ConfirmationRequest")]
        [Authorize(Roles = "Citizen, Blue collar")]
        public async Task<IActionResult> ConfirmationRequest(ConfirmIncident req)
        {
            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            if (user == null) return Unauthorized();

            var success = await _incidentService.ConfirmationImagesSubmission(req.IncidentId, req.ImagesUrl, req.Description, user.Id);

            if (!success)
                return StatusCode(StatusCodes.Status500InternalServerError);

            await _incidentService.AddToHistoryAsync(req.IncidentId, InterventionType.DoneRepairing, user.Id);

            return Ok();
        }

        [HttpPut("UnderRepair/{id}")]
        [Authorize(Roles = "Citizen, Blue collar")]
        public async Task<IActionResult> ChangeTaskStatusToUnderRepair(int id)
        {
           
            User? user = await _userManager.FindByIdAsync(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            if (user == null) return Unauthorized();

            var citizen = await _citizenService.GetCitizen(user.Id);
            if (citizen == null) return Unauthorized();

            var success = await _incidentService.ChangeTaskStatusToUnderRepair(id, citizen);

            if (!success)
                return NotFound();

            await _incidentService.AddToHistoryAsync(id, InterventionType.UnderRepair, user.Id);

            return Ok();
        }

        [Authorize]
        [HttpPut("Like/{incidentId}")]
        public async Task<IActionResult> ToggleLike(int incidentId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            await _incidentService.Like(userId, incidentId);

            return NoContent();
        }
    }
}