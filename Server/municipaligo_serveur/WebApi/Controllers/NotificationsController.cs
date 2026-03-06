using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Models.Models.DTOs;
using WebApi.Services;

namespace WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationsService _notificationsService;

        public NotificationsController(INotificationsService notificationsService)
        {
            _notificationsService = notificationsService;
        }


        [HttpPost("deviceToken")]
        [Authorize]
        public async Task<IActionResult> SaveDeviceToken([FromBody] DeviceTokenDTO dto)
        {
            var ok = await _notificationsService.SaveDeviceToken(dto);
            if (!ok)
            {
                return BadRequest();
            }
            return Ok();

        }


        [HttpPost("incidents/{id:int}/subscribe/toggle")]
        [Authorize(Roles = "Blue collar,Citizen")]
        public async Task<IActionResult> ToggleSubscription([FromRoute] int id)
        {
            var result = await _notificationsService.ToggleSubscription(id);

            if (result == null)
            { 
                return NotFound("incident not found");
            }

            return Ok(new
            {
                isSubscribed = result.Value.isSubscribed,
                isMandatory = result.Value.isMandatory
            });
        }

        [HttpGet("incidents/{id:int}/subscribe")]
        [Authorize(Roles = "Blue collar,Citizen")]
        public async Task<IActionResult> GetSubscriptionInfos([FromRoute] int id)
        {
            var result = await _notificationsService.GetSubscriptionInfo(id);

            if (result == null)
            {
                return NotFound("incident not found");
            }

            return Ok(new
            {
                isSubscribed = result.Value.isSubscribed,
                isMandatory = result.Value.isMandatory
            });

        }
    }
}



