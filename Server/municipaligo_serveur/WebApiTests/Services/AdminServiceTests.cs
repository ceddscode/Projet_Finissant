using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Models.Models;
using Models.Models.DTOs;
using Moq;
using municipaligo_serveur.Data;
using WebApi.Services;

namespace WebApi.Services.Tests
{
    [TestClass]
    public class AdminServiceTests
    {
        private ApplicationDbContext _db;
        private AdminService _service;
        private UserManager<User> _realUserManager;

        // 🔥 Centralized Mock Creator
        private Mock<UserManager<User>> CreateUserManagerMock()
        {
            var store = new Mock<IUserStore<User>>();

            return new Mock<UserManager<User>>(
                store.Object,
                null!, null!, null!, null!,
                null!, null!, null!, null!
            );
        }

        [TestInitialize]
        public void Init()
        {
            string dbName = "AdminTest_" + Guid.NewGuid();

            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(dbName)
                .Options;

            _db = new ApplicationDbContext(options);

            var roleStore = new RoleStore<IdentityRole>(_db);
            var roleManager = new RoleManager<IdentityRole>(
                roleStore, null, null, null, null
            );

            roleManager.CreateAsync(new IdentityRole("Admin")).GetAwaiter().GetResult();
            roleManager.CreateAsync(new IdentityRole("Citizen")).GetAwaiter().GetResult();

            var userStore = new UserStore<User>(_db);
            _realUserManager = new UserManager<User>(
                userStore,
                null, null, null, null,
                null, null, null, null
            );

            var user = new User
            {
                Id = "user-1",
                Email = "test@test.com",
                UserName = "test@test.com",
                PhoneNumber = "123456789"
            };

            _db.Users.Add(user);
            _db.SaveChanges();

            _realUserManager.AddToRoleAsync(user, "Citizen").GetAwaiter().GetResult();

            _db.Citizens.Add(new Citizen
            {
                UserId = "user-1",
                FirstName = "John",
                LastName = "Doe",
                City = "Montreal",
                RoadName = "TestRoad",
                PostalCode = "J0J0J0",
                RoadNumber = 123
            });

            _db.SaveChanges();

            _service = new AdminService(_db, _realUserManager);
        }

        [TestCleanup]
        public void Cleanup()
        {
            _db.Dispose();
        }

        // =============================
        // GET USERS
        // =============================

        [TestMethod]
        [ExpectedException(typeof(InvalidOperationException))]
        public async Task GetUsers_Throws_WhenUserManagerIsNull()
        {
            var service = new AdminService(_db, null!);
            await service.GetUsers();
        }

        [TestMethod]
        public async Task GetUsers_ReturnsEmpty_WhenNoUsersExist()
        {
            _db.Users.RemoveRange(_db.Users);
            await _db.SaveChangesAsync();

            var result = await _service.GetUsers();

            Assert.AreEqual(0, result.Count);
        }

        [TestMethod]
        public async Task GetUsers_SetsIsAdminTrue_WhenRoleIsAdmin()
        {
            var user = _db.Users.First();

            await _realUserManager.RemoveFromRoleAsync(user, "Citizen");
            await _realUserManager.AddToRoleAsync(user, "Admin");

            var result = await _service.GetUsers();

            Assert.IsTrue(result.First().IsAdmin);
        }

        [TestMethod]
        public async Task GetUsers_ReturnsUsers()
        {
            var result = await _service.GetUsers();

            Assert.AreEqual(1, result.Count);
            Assert.AreEqual("John", result.First().FirstName);
        }

        [TestMethod]
        public async Task GetUsers_ReturnsEmpty_WhenNoUsers()
        {
            _db.Users.RemoveRange(_db.Users);
            await _db.SaveChangesAsync();

            var result = await _service.GetUsers();

            Assert.AreEqual(0, result.Count);
        }

        [TestMethod]
        public async Task GetUsers_DefaultsToCitizen_WhenRolesNull()
        {
            var mock = CreateUserManagerMock();
            var user = _db.Users.First();

            mock.Setup(x => x.Users).Returns(_db.Users);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync((IList<string>)null!);

            var service = new AdminService(_db, mock.Object);

            var result = await service.GetUsers();

            Assert.AreEqual("Citizen", result.First().Role);
        }

        [TestMethod]
        public async Task GetUsers_DoesNotLoadCitizen_WhenAdmin()
        {
            var mock = CreateUserManagerMock();
            var user = _db.Users.First();

            mock.Setup(x => x.Users).Returns(_db.Users);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync(new List<string> { "Admin" });

            var service = new AdminService(_db, mock.Object);

            var result = await service.GetUsers();

            Assert.IsNull(result.First().FirstName);
        }

        // =============================
        // GET USER
        // =============================

        [TestMethod]
        public async Task GetUser_ReturnsUserDetails()
        {
            var result = await _service.GetUser("user-1");

            Assert.IsNotNull(result);
            Assert.AreEqual("John", result!.FirstName);
            Assert.AreEqual("Doe", result.LastName);
        }

        [TestMethod]
        public async Task GetUser_ReturnsNull_WhenUserNotFound()
        {
            var result = await _service.GetUser("invalid");
            Assert.IsNull(result);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public async Task GetUser_Throws_WhenIdInvalid()
        {
            await _service.GetUser("");
        }

        // =============================
        // EDIT USER ROLE LOGIC
        // =============================

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public async Task EditUser_Throws_WhenUserIdEmpty()
        {
            await _service.EditUserAsync("", new EditUserDto());
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentNullException))]
        public async Task EditUser_Throws_WhenDtoNull()
        {
            await _service.EditUserAsync("user-1", null!);
        }

        [TestMethod]
        public async Task EditUser_ReturnsNull_WhenUserNotFound()
        {
            var result = await _service.EditUserAsync("invalid", new EditUserDto());
            Assert.IsNull(result);
        }

        [TestMethod]
        [ExpectedException(typeof(Exception))]
        public async Task EditUser_Throws_WhenEmailUpdateFails()
        {
            var mock = CreateUserManagerMock();
            var user = _db.Users.First();

            mock.Setup(x => x.FindByIdAsync("user-1")).ReturnsAsync(user);
            mock.Setup(x => x.UpdateAsync(user))
                .ReturnsAsync(IdentityResult.Failed());

            var service = new AdminService(_db, mock.Object);

            await service.EditUserAsync("user-1",
                new EditUserDto { Email = "fail@test.com" });
        }

        [TestMethod]
        public async Task EditUser_UpdatesRoadNumber_WhenProvided()
        {
            await _service.EditUserAsync("user-1",
                new EditUserDto { RoadNumber = 999 });

            var citizen = _db.Citizens.First(c => c.UserId == "user-1");

            Assert.AreEqual(999, citizen.RoadNumber);
        }

        [TestMethod]
        public async Task EditUser_UpdatesPhoneNumber_WhenProvided()
        {
            await _service.EditUserAsync("user-1",
                new EditUserDto { PhoneNumber = "999999999" });

            var user = await _db.Users.FindAsync("user-1");

            Assert.AreEqual("999999999", user!.PhoneNumber);
        }

        [TestMethod]
        public async Task EditUser_CreatesCitizen_WhenNotExists()
        {
            var newUser = new User
            {
                Id = "user-2",
                Email = "user2@test.com",
                UserName = "user2@test.com"
            };

            _db.Users.Add(newUser);
            await _db.SaveChangesAsync();

            var dto = new EditUserDto
            {
                FirstName = "New",
                LastName = "Citizen",
                City = "Montreal",
                RoadName = "Main Street",
                PostalCode = "J0J0J0",
                RoadNumber = 10
            };

            var result = await _service.EditUserAsync("user-2", dto);

            Assert.IsNotNull(result);

            var citizen = _db.Citizens.FirstOrDefault(c => c.UserId == "user-2");

            Assert.IsNotNull(citizen);
            Assert.AreEqual("New", citizen!.FirstName);
        }

        [TestMethod]
        public async Task EditUser_ChangesRole_WhenDifferent()
        {
            var mock = CreateUserManagerMock();
            var user = _db.Users.First();

            mock.Setup(x => x.FindByIdAsync("user-1")).ReturnsAsync(user);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync(new List<string> { "Citizen" });
            mock.Setup(x => x.RemoveFromRolesAsync(user, It.IsAny<IEnumerable<string>>()))
                .ReturnsAsync(IdentityResult.Success);
            mock.Setup(x => x.AddToRoleAsync(user, "Admin"))
                .ReturnsAsync(IdentityResult.Success);

            var service = new AdminService(_db, mock.Object);

            var result = await service.EditUserAsync("user-1", new EditUserDto { Role = "Admin" });

            Assert.IsNotNull(result);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public async Task UpdateRole_Throws_WhenInvalidRole()
        {
            await _service.EditUserAsync("user-1",
                new EditUserDto { Role = "Hacker" });
        }

        [TestMethod]
        [ExpectedException(typeof(Exception))]
        public async Task UpdateRole_Throws_WhenCurrentRolesNull()
        {
            var mock = CreateUserManagerMock();
            var user = new User { Id = "user-1" };

            mock.Setup(x => x.FindByIdAsync("user-1")).ReturnsAsync(user);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync((IList<string>)null!);

            var service = new AdminService(_db, mock.Object);

            await service.EditUserAsync("user-1",
                new EditUserDto { Role = "Admin" });
        }

        [TestMethod]
        [ExpectedException(typeof(Exception))]
        public async Task UpdateRole_Throws_WhenAddFails()
        {
            var mock = CreateUserManagerMock();
            var user = new User { Id = "user-1" };

            mock.Setup(x => x.FindByIdAsync("user-1")).ReturnsAsync(user);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync(new List<string> { "Citizen" });
            mock.Setup(x => x.RemoveFromRolesAsync(user, It.IsAny<IEnumerable<string>>()))
                .ReturnsAsync(IdentityResult.Success);
            mock.Setup(x => x.AddToRoleAsync(user, "Admin"))
                .ReturnsAsync(IdentityResult.Failed());

            var service = new AdminService(_db, mock.Object);

            await service.EditUserAsync("user-1",
                new EditUserDto { Role = "Admin" });
        }

        [TestMethod]
        [ExpectedException(typeof(Exception))]
        public async Task UpdateRole_Throws_WhenRemoveFails()
        {
            var mock = CreateUserManagerMock();
            var user = new User { Id = "user-1" };

            mock.Setup(x => x.FindByIdAsync("user-1")).ReturnsAsync(user);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync(new List<string> { "Citizen" });
            mock.Setup(x => x.RemoveFromRolesAsync(user, It.IsAny<IEnumerable<string>>()))
                .ReturnsAsync(IdentityResult.Failed());

            var service = new AdminService(_db, mock.Object);

            await service.EditUserAsync("user-1",
                new EditUserDto { Role = "Admin" });
        }

        [TestMethod]
        [ExpectedException(typeof(Exception))]
        public async Task EditUser_Throws_WhenCurrentRolesNull()
        {
            var mock = CreateUserManagerMock();
            var user = new User { Id = "user-1" };

            mock.Setup(x => x.FindByIdAsync("user-1")).ReturnsAsync(user);
            mock.Setup(x => x.GetRolesAsync(user))
                .ReturnsAsync((IList<string>)null!);

            var service = new AdminService(_db, mock.Object);

            await service.EditUserAsync("user-1", new EditUserDto { Role = "Admin" });
        }
    }
}