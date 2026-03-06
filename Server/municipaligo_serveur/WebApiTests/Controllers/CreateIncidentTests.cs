using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;
using Moq;
using WebApi.Controllers;
using WebApi.Interfaces;
using WebApi.Services;

[TestClass]
public class CreateIncidentTests
{
    private Mock<IIncidentService> _mockIncidentService;
    private Mock<UserManager<User>> _mockUserManager;
    private Mock<CitizenService> _mockCitizenService;
    private IncidentsController _controller;

    [TestInitialize]
    public void Init()
    {
        _mockIncidentService = new Mock<IIncidentService>();

        var userStoreMock = new Mock<IUserStore<User>>();
        _mockUserManager = new Mock<UserManager<User>>(
            userStoreMock.Object, null, null, null, null, null, null, null, null
        );

        var dbContextMock = new Mock<municipaligo_serveur.Data.ApplicationDbContext>(
            new Microsoft.EntityFrameworkCore.DbContextOptions<municipaligo_serveur.Data.ApplicationDbContext>()
        );
        _mockCitizenService = new Mock<CitizenService>(dbContextMock.Object);

        _controller = new IncidentsController(
            _mockIncidentService.Object,
            _mockUserManager.Object,
            _mockCitizenService.Object
        );
    }

    private void SetUser(string? userId)
    {
        var claims = userId != null
            ? new[] { new Claim(ClaimTypes.NameIdentifier, userId) }
            : Array.Empty<Claim>();

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"))
            }
        };
    }

    private ReportIncident BuildValidRequest() => new ReportIncident
    {
        Title = "Nid de poule",
        Description = "Gros trou dans la route",
        Location = "Rue Principale, Vieux-Longueuil",
        ImagesUrl = new List<string> { "img1.jpg" },
        Longitude = -73.5,
        Latitude = 45.5,
        Category = Category.Mobilier
    };

    [TestMethod]
    public async Task CreateIncident_ReturnsBadRequest_WhenModelStateIsInvalid()
    {
        SetUser("test-user-id");
        _controller.ModelState.AddModelError("Title", "Le titre est requis");

        var result = await _controller.CreateIncident(BuildValidRequest());

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }

    [TestMethod]
    public async Task CreateIncident_ReturnsUnauthorized_WhenUserNotFound()
    {
        SetUser("unknown-user-id");

        _mockUserManager
            .Setup(u => u.FindByIdAsync(It.IsAny<string>()))
            .ReturnsAsync((User?)null);

        var result = await _controller.CreateIncident(BuildValidRequest());

        Assert.IsInstanceOfType(result.Result, typeof(UnauthorizedResult));
    }

    [TestMethod]
    public async Task CreateIncident_ReturnsBadRequest_WhenRequestIsNull()
    {
        SetUser("test-user-id");

        _mockUserManager
            .Setup(u => u.FindByIdAsync("test-user-id"))
            .ReturnsAsync(new User { Id = "test-user-id" });

        var result = await _controller.CreateIncident(null!);

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestResult));
    }

    [TestMethod]
    public async Task CreateIncident_ReturnsCreatedAtAction_WhenRequestIsValid()
    {
        SetUser("test-user-id");

        var user = new User { Id = "test-user-id" };
        _mockUserManager
            .Setup(u => u.FindByIdAsync("test-user-id"))
            .ReturnsAsync(user);

        _mockIncidentService
            .Setup(s => s.PostIncident(It.IsAny<Incident>()))
            .Returns(Task.CompletedTask);

        _mockIncidentService
            .Setup(s => s.AddToHistoryAsync(
                It.IsAny<int>(),
                InterventionType.Created,
                "test-user-id"))
            .Returns(Task.CompletedTask);

        var req = BuildValidRequest();

        var result = await _controller.CreateIncident(req);

        var createdResult = result.Result as CreatedAtActionResult;
        Assert.IsNotNull(createdResult, "Le résultat devrait être un CreatedAtActionResult");
        Assert.AreEqual(nameof(_controller.GetIncidentDetails), createdResult.ActionName);

        var incident = createdResult.Value as Incident;
        Assert.IsNotNull(incident);
        Assert.AreEqual("Nid de poule", incident.Title);
        Assert.AreEqual("Rue Principale, Vieux-Longueuil", incident.Location);
        Assert.AreEqual("test-user-id", incident.CitizenUserId);
        Assert.AreEqual(Status.WaitingForValidation, incident.Status);
        Assert.AreEqual(Category.Mobilier, incident.Categories);
        Assert.AreEqual("Vieux-Longueuil", incident.Quartier);
        Assert.IsNull(incident.AssignedAt);

        _mockIncidentService.Verify(
            s => s.PostIncident(It.IsAny<Incident>()),
            Times.Once
        );
        _mockIncidentService.Verify(
            s => s.AddToHistoryAsync(It.IsAny<int>(), InterventionType.Created, "test-user-id"),
            Times.Once
        );
    }

    [TestMethod]
    public async Task CreateIncident_Returns500_WhenPostIncidentThrows()
    {
        SetUser("test-user-id");

        _mockUserManager
            .Setup(u => u.FindByIdAsync("test-user-id"))
            .ReturnsAsync(new User { Id = "test-user-id" });

        _mockIncidentService
            .Setup(s => s.PostIncident(It.IsAny<Incident>()))
            .ThrowsAsync(new Exception("Erreur DB simulée"));

        var result = await _controller.CreateIncident(BuildValidRequest());

        var statusResult = result.Result as ObjectResult;
        Assert.IsNotNull(statusResult);
        Assert.AreEqual(500, statusResult.StatusCode);
        StringAssert.Contains(statusResult.Value?.ToString(), "Erreur DB simulée");
    }

    [TestMethod]
    public async Task CreateIncident_Returns500_WhenAddToHistoryThrows()
    {
        SetUser("test-user-id");

        _mockUserManager
            .Setup(u => u.FindByIdAsync("test-user-id"))
            .ReturnsAsync(new User { Id = "test-user-id" });

        _mockIncidentService
            .Setup(s => s.PostIncident(It.IsAny<Incident>()))
            .Returns(Task.CompletedTask);

        _mockIncidentService
            .Setup(s => s.AddToHistoryAsync(
                It.IsAny<int>(),
                It.IsAny<InterventionType>(),
                It.IsAny<string>()))
            .ThrowsAsync(new Exception("Erreur historique simulée"));

        var result = await _controller.CreateIncident(BuildValidRequest());

        var statusResult = result.Result as ObjectResult;
        Assert.IsNotNull(statusResult);
        Assert.AreEqual(500, statusResult.StatusCode);
        StringAssert.Contains(statusResult.Value?.ToString(), "Erreur historique simulée");
    }
}