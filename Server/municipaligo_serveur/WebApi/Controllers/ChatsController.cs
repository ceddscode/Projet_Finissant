using System.Security.Claims;
using Google.Apis.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Models.Models;
using Models.Models.DTOs;
using WebApi.Interfaces;
using WebApi.Services;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly CitizenService _citizenService;
    private readonly IIncidentService _incidentService;

    public ChatController(IChatService chatService, CitizenService citizenService, IIncidentService incidentService)
    {
        _chatService = chatService;
        _citizenService = citizenService;
        _incidentService = incidentService;
    }

    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var userId = GetUserId();
        var conversations = await _chatService.GetConversationsAsync(userId);
        return Ok(conversations);
    }

    [HttpGet("messages/{partnerUserId}")]
    public async Task<IActionResult> GetMessages(int partnerUserId, [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var userId = GetUserId();
        var messages = await _chatService.GetMessagesAsync(userId, partnerUserId, page, pageSize);
        return Ok(messages);
    }

    [HttpGet("users")]
    public async Task<IActionResult> SearchUsers([FromQuery] string? search)
    {
        var userId = GetUserId();
        var users = await _chatService.SearchUsersAsync(userId, search);
        return Ok(users);
    }

    [HttpPost("messages/read/{partnerUserId}")]
    public async Task<IActionResult> MarkAsRead(int partnerUserId)
    {
        var userId = GetUserId();
        await _chatService.MarkMessagesAsReadAsync(userId, partnerUserId);
        return NoContent();
    }

    [HttpDelete("conversations/{partnerCitizenId}")]
    public async Task<IActionResult> HideConversation(int partnerCitizenId)
    {
        var userId = GetUserId();
        await _chatService.HideConversationAsync(userId, partnerCitizenId);
        return NoContent();
    }

    [HttpGet("incidents")]
    public async Task<IActionResult> GetIncidents()
    {
        var userId = GetUserId();
        var incidents = await _incidentService.GetValidatedIncidents(userId);

        var result = incidents.Select(i => new SharedIncidentDto(
            i.Id,
            i.Title,
            i.Status,
            i.Category,
            i.Location,
            i.ImagesUrl[0]
        ));

        return Ok(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new UnauthorizedAccessException();
}