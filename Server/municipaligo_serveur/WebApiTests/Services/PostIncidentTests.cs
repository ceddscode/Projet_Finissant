//using Microsoft.AspNetCore.Identity;
//using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
//using Microsoft.Data.Sqlite;
//using Microsoft.EntityFrameworkCore;
//using Microsoft.VisualStudio.TestTools.UnitTesting;
//using Models.Models;
//using Models.Models.Enums;
//using Moq;
//using municipaligo_serveur.Data;
//using WebApi.Services;

//[TestClass]
//public class PostIncidentTests
//{
//    private ApplicationDbContext _db;
//    private IncidentService _service;
//    private Mock<INotificationsService> _mockNotificationsService;
//    private SqliteConnection _connection;

//    [TestInitialize]
//    public void Init()
//    {
//        _connection = new SqliteConnection("DataSource=:memory:");
//        _connection.Open();

//        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
//            .UseSqlite(_connection)
//            .Options;

//        _db = new ApplicationDbContext(options);
//        _db.Database.EnsureCreated();

//        _db.Users.Add(new User { Id = "valid-user-id", UserName = "testuser" });
//        _db.SaveChanges();

//        _mockNotificationsService = new Mock<INotificationsService>();
//        _mockNotificationsService
//            .Setup(n => n.CreateMandatorySubscription(It.IsAny<int>(), It.IsAny<string>()))
//            .Returns(Task.CompletedTask);

//        var userStore = new UserStore<User>(_db);
//        var userManager = new UserManager<User>(
//            userStore, null, null, null, null, null, null, null, null
//        );

//        _service = new IncidentService(_db, userManager, _mockNotificationsService.Object);
//    }

//    [TestCleanup]
//    public void Cleanup()
//    {
//        _db.Dispose();
//        _connection.Close();
//        _connection.Dispose();
//    }

//    private Incident BuildValidIncident(string? citizenUserId = "valid-user-id") => new Incident(
//        0,
//        "Nid de poule",
//        "Description",
//        "Rue Principale, Vieux-Longueuil",
//        DateTime.UtcNow,
//        null,
//        Category.Mobilier,
//        Status.WaitingForValidation,
//        null,
//        null,
//        citizenUserId,
//        null,
//        new List<string> { "img1.jpg" },
//        null,
//        null,
//        null,
//        45.5,
//        -73.5,
//        0,
//        "Vieux-Longueuil"
//    );

//    [TestMethod]
//    public async Task PostIncident_ThrowsArgumentNullException_WhenIncidentIsNull()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<ArgumentNullException>(
//            () => _service.PostIncident(null!)
//        );

//        StringAssert.Contains(ex.Message, "incident");
//    }

//    [TestMethod]
//    public async Task PostIncident_ThrowsInvalidOperationException_WhenStatusIsNotWaitingForValidation()
//    {
//        var incident = BuildValidIncident();
//        incident.Status = Status.WaitingForAssignation;

//        var ex = await Assert.ThrowsExceptionAsync<InvalidOperationException>(
//            () => _service.PostIncident(incident)
//        );

//        StringAssert.Contains(ex.Message, "WaitingForValidation");
//    }

//    [TestMethod]
//    public async Task PostIncident_ThrowsInvalidOperationException_AndRollsBack_WhenCitizenUserIdNotInDb()
//    {
//        var incident = BuildValidIncident(citizenUserId: "inexistant-user-id");

//        var ex = await Assert.ThrowsExceptionAsync<InvalidOperationException>(
//            () => _service.PostIncident(incident)
//        );

//        StringAssert.Contains(ex.Message, "Le citoyen n'existe pas");

//        _mockNotificationsService.Verify(
//            n => n.CreateMandatorySubscription(It.IsAny<int>(), It.IsAny<string>()),
//            Times.Never
//        );
//    }

//    [TestMethod]
//    public async Task PostIncident_CommitsWithoutNotification_WhenCitizenUserIdIsNull()
//    {
//        var incident = BuildValidIncident(citizenUserId: null);

//        await _service.PostIncident(incident);

//        var saved = await _db.Incidents.FindAsync(incident.Id);
//        Assert.IsNotNull(saved);
//        Assert.AreEqual("Nid de poule", saved.Title);

//        _mockNotificationsService.Verify(
//            n => n.CreateMandatorySubscription(It.IsAny<int>(), It.IsAny<string>()),
//            Times.Never
//        );
//    }

//    [TestMethod]
//    public async Task PostIncident_CommitsWithoutNotification_WhenCitizenUserIdIsEmpty()
//    {
//        var incident = BuildValidIncident(citizenUserId: "");

//        await _service.PostIncident(incident);

//        var saved = await _db.Incidents.FindAsync(incident.Id);
//        Assert.IsNotNull(saved);

//        _mockNotificationsService.Verify(
//            n => n.CreateMandatorySubscription(It.IsAny<int>(), It.IsAny<string>()),
//            Times.Never
//        );
//    }

//    [TestMethod]
//    public async Task PostIncident_SavesIncidentAndCallsNotification_WhenAllParametersAreValid()
//    {
//        var incident = BuildValidIncident(citizenUserId: "valid-user-id");

//        await _service.PostIncident(incident);

//        var saved = await _db.Incidents.FindAsync(incident.Id);
//        Assert.IsNotNull(saved);
//        Assert.AreEqual("Nid de poule", saved.Title);
//        Assert.AreEqual("valid-user-id", saved.CitizenUserId);
//        Assert.AreEqual(Status.WaitingForValidation, saved.Status);

//        _mockNotificationsService.Verify(
//            n => n.CreateMandatorySubscription(incident.Id, "valid-user-id"),
//            Times.Once
//        );
//    }
//}