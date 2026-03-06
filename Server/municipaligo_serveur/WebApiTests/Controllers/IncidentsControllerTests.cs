using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Models.Models;
using Models.Models.Enums;
using municipaligo_serveur.Data;
using WebApi.Controllers;
using WebApi.Services;

[TestClass]
public class IncidentsControllerTests
{
    private ApplicationDbContext _db;
    private IncidentsController _controller;
    private IncidentService _service;


    [TestInitialize]
    public void Init()
    {
        // DB unique par test (comme dans les notes)
        string dbName = "IncidentsTest_" + Guid.NewGuid();

        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;

        _db = new ApplicationDbContext(options);

        // Données de test
        var citizen = new Citizen
        {
            Id = 1,
            FirstName = "Test",
            LastName = "Citizen",
            City = "TestCity",
            RoadName = "TestRoad",
            PostalCode = "J0J0J0",
            UserId = "test-user-id"
        };

        _db.Citizens.Add(citizen);
        _db.Incidents.AddRange(
        new Incident
        {
            Id = 1,
            Title = "Incident 1",
            Description = "Description 1",
            Location = "Location 1",
            Status = Status.WaitingForValidation,
            Citizen = citizen
        },
        new Incident
        {
            Id = 2,
            Title = "Incident 2",
            Description = "Description 2",
            Location = "Location 2",
            Status = Status.WaitingForAssignation,
            Citizen = citizen
        },
        new Incident
        {
            Id = 3,
            Title = "Incident 3",
            Description = "Description 3",
            Location = "Location 3",
            Status = Status.WaitingForAssignation,
            Citizen = citizen
        }
    );
        _db.SaveChanges();

        // UserManager réel minimal (sans mock)
        var userStore = new UserStore<User>(_db);

        var userManager = new UserManager<User>(
            userStore,
            null, null, null, null, null, null, null, null
        );


        //_service = new IncidentService(_db,userManager);
        //_controller = new IncidentsController(userManager);
    }

    [TestCleanup]
    public void Dispose()
    {
        _db.Dispose();
    }

    // ============================
    // TEST: none-accepted
    // ============================
    [TestMethod]
    public async Task GetincidentsNoneAccepted_ReturnsOnlyWaitingForValidation()
    {
        var result = await _service.GetNotValidatedIncidents();
        var incidents = result.ToList();

        Assert.AreEqual(1, incidents.Count);
        Assert.IsTrue(incidents.All(i => i.Status == Status.WaitingForValidation));
    }

    // ============================
    // TEST: accepted
    // ============================
    [TestMethod]
    public async Task GetincidentAccepted_ReturnsOnlyValidated(string? userid)
    {
        var result = await _service.GetValidatedIncidents(userid);
        var incidents = result.ToList();

        Assert.AreEqual(2, incidents.Count);
        Assert.IsTrue(incidents.All(i => i.Status == Status.WaitingForAssignation));
    }

    [TestMethod]
    public async Task ConfirmationImagesSubmission_ReturnsFalse_WhenIncidentDoesNotExist()
    {
        // Act
        var result = await _service.ConfirmationImagesSubmission(
            incidentId: 999,
            confirmationImagesUrls: new List<string> { "img1.jpg" },
            description: "desc",
            userId: "test-user-id"
        );

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task ConfirmationImagesSubmission_ReturnsFalse_WhenUserIsNotOwner()
    {
        // Arrange
        var incident = _db.Incidents.First(i => i.Id == 1);
        incident.CitizenUserId = "owner-user-id";
        await _db.SaveChangesAsync();

        // Act
        var result = await _service.ConfirmationImagesSubmission(
            incidentId: 1,
            confirmationImagesUrls: new List<string> { "img1.jpg" },
            description: "desc",
            userId: "other-user-id"
        );

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task ConfirmationImagesSubmission_UpdatesDescriptionAndImages_WhenValid()
    {
        // Arrange
        var incident = _db.Incidents.First(i => i.Id == 1);
        incident.CitizenUserId = "test-user-id";
        incident.ConfirmationImagesUrl = new List<string>();
        await _db.SaveChangesAsync();

        var images = new List<string> { "img1.jpg", "img2.jpg" };

        // Act
        var result = await _service.ConfirmationImagesSubmission(
            incidentId: 1,
            confirmationImagesUrls: images,
            description: "confirmation ok",
            userId: "test-user-id"
        );

        // Assert
        Assert.IsTrue(result);

        var updatedIncident = await _db.Incidents.FindAsync(1);
        Assert.IsNotNull(updatedIncident);
        Assert.AreEqual("confirmation ok", updatedIncident!.ConfirmationDescription);
        Assert.AreEqual(2, updatedIncident.ConfirmationImagesUrl.Count);
        CollectionAssert.AreEquivalent(images, updatedIncident.ConfirmationImagesUrl);
    }

    // ============================
    // TESTS: ConfirmIncidentAsync
    // ============================

    [TestMethod]
    public async Task ConfirmIncidentAsync_ReturnsFalse_WhenIncidentDoesNotExist()
    {
        // Act
        var result = await _service.ConfirmIncidentAsync(999);

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task ConfirmIncidentAsync_ReturnsTrue_AndSetsStatusToDone_WhenIncidentExists()
    {
        // Arrange
        var incident = _db.Incidents.First(i => i.Id == 1);
        incident.Status = Status.WaitingForAssignation;
        await _db.SaveChangesAsync();

        // Act
        var result = await _service.ConfirmIncidentAsync(1);

        // Assert
        Assert.IsTrue(result);

        var updatedIncident = await _db.Incidents.FindAsync(1);
        Assert.IsNotNull(updatedIncident);
        Assert.AreEqual(Status.Done, updatedIncident!.Status);
    }

    // ============================
    // TESTS: RefuseIncidentAsync
    // ============================

    [TestMethod]
    public async Task RefuseIncidentAsync_ReturnsFalse_WhenIncidentDoesNotExist()
    {
        // Act
        var result = await _service.RefuseIncidentAsync(999, "raison du refus");

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task RefuseIncidentAsync_UpdatesIncidentCorrectly_WhenIncidentExists()
    {
        // Arrange
        var incident = _db.Incidents.First(i => i.Id == 1);
        incident.Status = Status.WaitingForAssignation;
        incident.ConfirmationDescription = "ancienne description";
        incident.RefusalDescription = null;
        incident.ConfirmationImagesUrl = new List<string>
    {
        "img1.jpg",
        "img2.jpg"
    };
        await _db.SaveChangesAsync();

        var refusalReason = "Photos non conformes";

        // Act
        var result = await _service.RefuseIncidentAsync(1, refusalReason);

        // Assert
        Assert.IsTrue(result);

        var updatedIncident = await _db.Incidents.FindAsync(1);
        Assert.IsNotNull(updatedIncident);

        Assert.AreEqual(Status.AssignedToCitizen, updatedIncident!.Status);
        Assert.AreEqual(refusalReason, updatedIncident.RefusalDescription);
        Assert.AreEqual(string.Empty, updatedIncident.ConfirmationDescription);
        Assert.AreEqual(0, updatedIncident.ConfirmationImagesUrl.Count);
    }



}
