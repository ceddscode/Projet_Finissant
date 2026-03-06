using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Models.Models.DTOs;
using WebApi.Controllers;
using WebApi.Services;
using Moq;
using Microsoft.AspNetCore.Identity;
using Models.Models;
using System;

[TestClass]
public class AdminControllerTests
{
    private Mock<IAdminService> _serviceMock;
    private Mock<UserManager<User>> _userManagerMock;

    private AdminController _controller;

    [TestInitialize]
    public void Init()
    {
        _serviceMock = new Mock<IAdminService>();

        var store = new Mock<IUserStore<User>>();
        _userManagerMock = new Mock<UserManager<User>>(
            store.Object, null!, null!, null!, null!, null!, null!, null!, null!);



        _controller = new AdminController(
            _serviceMock.Object,
            _userManagerMock.Object,
            null!,
            null!);
    }

    // =============================
    // GET USERS
    // =============================

    [TestMethod]
    public async Task GetUsers_ReturnsOk_WhenUsersExist()
    {
        _serviceMock.Setup(s => s.GetUsers())
            .ReturnsAsync(new List<UserListDto>
            {
                new UserListDto { Id = "1", Email = "test@test.com" }
            });

        var result = await _controller.GetUsers();

        Assert.IsInstanceOfType(result.Result, typeof(OkObjectResult));
    }

    [TestMethod]
    public async Task GetUsers_ReturnsNoContent_WhenEmpty()
    {
        _serviceMock.Setup(s => s.GetUsers())
            .ReturnsAsync(new List<UserListDto>());

        var result = await _controller.GetUsers();

        Assert.IsInstanceOfType(result.Result, typeof(NoContentResult));
    }

    [TestMethod]
    public async Task GetUsers_Returns500_WhenException()
    {
        _serviceMock.Setup(s => s.GetUsers())
            .ThrowsAsync(new Exception("error"));

        var result = await _controller.GetUsers();

        Assert.IsInstanceOfType(result.Result, typeof(ObjectResult));
        Assert.AreEqual(500, ((ObjectResult)result.Result!).StatusCode);
    }

    // =============================
    // GET USER
    // =============================

    [TestMethod]
    public async Task GetUser_ReturnsBadRequest_WhenIdInvalid()
    {
        var result = await _controller.GetUser("");

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }

    [TestMethod]
    public async Task GetUser_ReturnsNotFound_WhenNull()
    {
        _serviceMock.Setup(s => s.GetUser("1"))
            .ReturnsAsync((EditUserDto?)null);

        var result = await _controller.GetUser("1");

        Assert.IsInstanceOfType(result.Result, typeof(NotFoundObjectResult));
    }

    [TestMethod]
    public async Task GetUser_ReturnsOk_WhenFound()
    {
        _serviceMock.Setup(s => s.GetUser("1"))
            .ReturnsAsync(new EditUserDto());

        var result = await _controller.GetUser("1");

        Assert.IsInstanceOfType(result.Result, typeof(OkObjectResult));
    }

    [TestMethod]
    public async Task GetUser_Returns500_WhenException()
    {
        _serviceMock.Setup(s => s.GetUser("1"))
            .ThrowsAsync(new Exception());

        var result = await _controller.GetUser("1");

        Assert.AreEqual(500, ((ObjectResult)result.Result!).StatusCode);
    }

    // =============================
    // EDIT USER
    // =============================

    [TestMethod]
    public async Task EditUser_CallsService_WithRole_WhenRoleProvided()
    {
        var dto = new EditUserDto
        {
            Role = "Admin"
        };

        _serviceMock
            .Setup(s => s.EditUserAsync("1", It.IsAny<EditUserDto>()))
            .ReturnsAsync(new UserListDto { Id = "1" });

        await _controller.EditUser("1", dto);

        _serviceMock.Verify(s =>
            s.EditUserAsync("1",
                It.Is<EditUserDto>(d => d.Role == "Admin")),
            Times.Once);
    }

    [TestMethod]
    public async Task EditUser_ReturnsBadRequest_WhenArgumentException()
    {
        _serviceMock.Setup(s => s.EditUserAsync("1", It.IsAny<EditUserDto>()))
            .ThrowsAsync(new ArgumentException("Invalid role"));

        var result = await _controller.EditUser("1", new EditUserDto());

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }

    [TestMethod]
    public async Task EditUser_ReturnsBadRequest_WhenIdInvalid()
    {
        var result = await _controller.EditUser("", new EditUserDto());

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }

    [TestMethod]
    public async Task EditUser_ReturnsBadRequest_WhenDtoNull()
    {
        var result = await _controller.EditUser("1", null!);

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }

    [TestMethod]
    public async Task EditUser_ReturnsBadRequest_WhenModelStateInvalid()
    {
        _controller.ModelState.AddModelError("error", "invalid");

        var result = await _controller.EditUser("1", new EditUserDto());

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }
    [TestMethod]
    public async Task EditUser_ReturnsNotFound_WhenUserDoesNotExist()
    {
        _serviceMock.Setup(s => s.EditUserAsync("1", It.IsAny<EditUserDto>()))
            .ReturnsAsync((UserListDto?)null);

        var result = await _controller.EditUser("1", new EditUserDto());

        Assert.IsInstanceOfType(result.Result, typeof(NotFoundObjectResult));
    }

    [TestMethod]
    public async Task EditUser_Returns500_WhenException()
    {
        _serviceMock.Setup(s => s.EditUserAsync("1", It.IsAny<EditUserDto>()))
            .ThrowsAsync(new Exception());

        var result = await _controller.EditUser("1", new EditUserDto());

        Assert.AreEqual(500, ((ObjectResult)result.Result!).StatusCode);
    }

    [TestMethod]
    public async Task EditUser_ReturnsOk_WhenUpdated()
    {
        _serviceMock.Setup(s => s.EditUserAsync("1", It.IsAny<EditUserDto>()))
            .ReturnsAsync(new UserListDto { Id = "1" });

        var result = await _controller.EditUser("1", new EditUserDto());

        Assert.IsInstanceOfType(result.Result, typeof(OkObjectResult));
    }


}
