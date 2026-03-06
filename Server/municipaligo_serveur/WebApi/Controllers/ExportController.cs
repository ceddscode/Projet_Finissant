using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
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
    public class ExportController : ControllerBase

    {
        private readonly UserManager<User> _userManager;
        private readonly CitizenService _citizenService;
        private readonly IIncidentService _incidentService;
        private readonly ExportService _exportService;
        public ExportController(IIncidentService incidentService, UserManager<User> userManager, CitizenService citizenService, ExportService exportService)
        {
            _incidentService = incidentService;
            _userManager = userManager;
            _citizenService = citizenService;
            _exportService = exportService;
        }
        [HttpPost("PDF")]
        public async Task<IActionResult> ExportIncidents([FromBody] QueryParametersDTO filter)
        {
            bool isAdmin = User.IsInRole("Admin");

            var pdfBytes = await _exportService.ExportPDF(filter, isAdmin);

            return File(pdfBytes, "application/pdf", "Incidents.pdf");
        }

        [HttpPost("Excel")]
        public async Task<IActionResult> ExportExcel([FromBody] QueryParametersDTO filter)
        {
            bool isAdmin = User.IsInRole("Admin");
            var excel = await _exportService.ExportExcel(filter, isAdmin);

            return File(
                excel,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "incidents.xlsx"
            );
        }

        [HttpPost("CSV")]
        public async Task<IActionResult> ExportCSV([FromBody] QueryParametersDTO filter)
        {
            bool isAdmin = User.IsInRole("Admin");
            var csv = await _exportService.ExportCSV(filter, isAdmin);

            return File(csv,"text/csv","incidents.csv");
        }

        [HttpPost("JSON")]
        public async Task<IActionResult> ExportJson([FromBody] QueryParametersDTO filter)
        {
            bool isAdmin = User.IsInRole("Admin");
            var json = await _exportService.ExportJson(filter, isAdmin);

            return File(json, "application/json", "incidents.json");
        }
    }
}
