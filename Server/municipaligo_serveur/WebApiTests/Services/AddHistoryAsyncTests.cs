//using Microsoft.AspNetCore.Identity;
//using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
//using Microsoft.EntityFrameworkCore;
//using Microsoft.VisualStudio.TestTools.UnitTesting;
//using Models.Models;
//using Models.Models.Enums;
//using Moq;
//using municipaligo_serveur.Data;
//using WebApi.Services;

//[TestClass]
//public class AddToHistoryAsyncTests
//{
//    private ApplicationDbContext _db;
//    private IncidentService _service;
//    private Mock<INotificationsService> _mockNotificationsService;

//    [TestInitialize]
//    public void Init()
//    {
//        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
//            .UseInMemoryDatabase("AddToHistoryTest_" + Guid.NewGuid())
//            .Options;

//        _db = new ApplicationDbContext(options);

//        _db.Incidents.Add(new Incident(
//            1, "Titre", "Description", "Location",
//            DateTime.UtcNow, null, Category.Mobilier,
//            Status.WaitingForValidation, null, null,
//            "valid-user-id", null, new List<string>(),
//            null, null, null, 45.5, -73.5, 0, null
//        ));

//        _db.Users.Add(new User { Id = "valid-user-id", UserName = "testuser" });

//        _db.SaveChanges();

//        _mockNotificationsService = new Mock<INotificationsService>();
//        _mockNotificationsService
//            .Setup(n => n.CreateMandatorySubscription(It.IsAny<int>(), It.IsAny<string>()))
//            .Returns(Task.CompletedTask);
//        _mockNotificationsService
//            .Setup(n => n.SendStatusChangeNotification(It.IsAny<int>(), It.IsAny<Status>(), It.IsAny<string?>()))
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
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsArgumentException_WhenIncidentIdIsNegative()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<ArgumentException>(
//            () => _service.AddToHistoryAsync(-1, InterventionType.Created, "valid-user-id")
//        );

//        StringAssert.Contains(ex.Message, "IncidentId invalide.");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsInvalidOperationException_WhenIncidentIdIsZeroAndNotInDb()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<InvalidOperationException>(
//            () => _service.AddToHistoryAsync(0, InterventionType.Created, "valid-user-id")
//        );

//        StringAssert.Contains(ex.Message, "Incident inexistant.");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsArgumentException_WhenUserIdIsNull()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<ArgumentException>(
//            () => _service.AddToHistoryAsync(1, InterventionType.Created, null!)
//        );

//        StringAssert.Contains(ex.Message, "UserId est requis.");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsArgumentException_WhenUserIdIsWhitespace()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<ArgumentException>(
//            () => _service.AddToHistoryAsync(1, InterventionType.Created, "   ")
//        );

//        StringAssert.Contains(ex.Message, "UserId est requis.");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsArgumentException_WhenInterventionTypeIsInvalid()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<ArgumentException>(
//            () => _service.AddToHistoryAsync(1, (InterventionType)999, "valid-user-id")
//        );

//        StringAssert.Contains(ex.Message, "InterventionType invalide.");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsInvalidOperationException_WhenIncidentDoesNotExist()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<InvalidOperationException>(
//            () => _service.AddToHistoryAsync(999, InterventionType.Created, "valid-user-id")
//        );

//        StringAssert.Contains(ex.Message, "Incident inexistant.");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_ThrowsInvalidOperationException_WhenUserDoesNotExist()
//    {
//        var ex = await Assert.ThrowsExceptionAsync<InvalidOperationException>(
//            () => _service.AddToHistoryAsync(1, InterventionType.Created, "inexistant-user-id")
//        );

//        StringAssert.Contains(ex.Message, "User inexistant");
//    }

//    [TestMethod]
//    public async Task AddToHistoryAsync_SavesIncidentHistory_WhenAllParametersAreValid()
//    {
//        await _service.AddToHistoryAsync(1, InterventionType.Created, "valid-user-id");

//        var history = _db.IncidentHistories.FirstOrDefault();
//        Assert.IsNotNull(history, "L'historique devrait avoir été sauvegardé");
//        Assert.AreEqual(1, history.IncidentId);
//        Assert.AreEqual("valid-user-id", history.UserId);
//        Assert.AreEqual(InterventionType.Created, history.InterventionType);
//        Assert.AreEqual(1, _db.IncidentHistories.Count());
//    }
//}
