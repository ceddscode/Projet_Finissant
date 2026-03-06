using System.Reflection.Metadata.Ecma335;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.CodeAnalysis;
using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;
using WebApi.Services;

namespace WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatsController : ControllerBase
    {
       
        private readonly UserManager<User> _userManager;
       
        private readonly StatsService _statsService;


        public StatsController(UserManager<User> userManager, StatsService statsService)
        {
            
            _userManager = userManager;

            _statsService = statsService;
        }

        [HttpGet("resolution")]
        public async Task<IActionResult> GetResolution([FromQuery] Category? category)
        {
            var result = await _statsService.GetAverageResolutionTime(category);
            return Ok(result);
        }

        [HttpGet("charge")]
        public async Task<IActionResult> GetInCharge([FromQuery] Category? category)
        {
            var result = await _statsService.GetAverageInChargeTime(category);
            return Ok(result);
        }

        [HttpGet("total")]
        public async Task<IActionResult> GetSolved([FromQuery] Category? category)
        {
            var result = await _statsService.GetSolvedIncidentsNumber(category);
            return Ok(result);
        }

        [HttpGet("AssignTime")]
        public async Task<IActionResult> GetAssignmentTime(Category? category)
        {
            var result = await _statsService.GetAssignmentTime(category);
            return Ok(result);
        }

        [HttpGet("categories-chart")]
        public async Task<IActionResult> GetCategoriesChart(string period)
        {
            var data = await _statsService.GetCategoriesChart(period);
            return Ok(data);
        }

        [HttpGet("evolution-chart")]
        public async Task<IActionResult> GetEvolutionChart(string period)
        {
            var data = await _statsService.GetEvolutionChart(period);
            return Ok(data);
        }

    }
}