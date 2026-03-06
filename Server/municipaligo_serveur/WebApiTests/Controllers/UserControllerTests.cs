//using System.Text.Json;
//using Microsoft.AspNetCore.Http;
//using Microsoft.AspNetCore.Identity;
//using Microsoft.AspNetCore.Mvc;
//using Microsoft.EntityFrameworkCore;
//using Microsoft.Extensions.Configuration;
//using Microsoft.Extensions.DependencyInjection;
//using Microsoft.VisualStudio.TestTools.UnitTesting;
//using Models.Models;
//using Models.Models.DTOs;
//using municipaligo_serveur.Data;
//using WebApi.Controllers;
//using WebApi.Services;

//namespace WebApi.Controllers.Tests
//{
//    [TestClass]
//    public class UserControllerTests
//    {
//        private ServiceProvider _sp = null!;
//        private ApplicationDbContext _db = null!;
//        private UserManager<User> _userManager = null!;
//        private IConfiguration _config = null!;
//        private ClientAccessService _clientAccessService = null!;

//        [TestInitialize]
//        public async Task Setup()
//        {
//            var services = new ServiceCollection();

//            services.AddLogging();

//            services.AddDbContext<ApplicationDbContext>(o =>
//                o.UseInMemoryDatabase(Guid.NewGuid().ToString()));

//            services.AddIdentity<User, IdentityRole>()
//                .AddEntityFrameworkStores<ApplicationDbContext>()
//                .AddDefaultTokenProviders();

//            _config = new ConfigurationBuilder()
//                .AddInMemoryCollection(new Dictionary<string, string?>
//                {
//                    ["Jwt:Key"] = "THIS_IS_A_SUPER_LONG_SECRET_KEY_32CHARS_MIN!!!",
//                    ["Jwt:Issuer"] = "http://test",
//                    ["Jwt:Audience"] = "http://test",
//                    ["Jwt:ExpiresMinutes"] = "30"
//                })
//                .Build();

//            _sp = services.BuildServiceProvider();
//            _db = _sp.GetRequiredService<ApplicationDbContext>();
//            _userManager = _sp.GetRequiredService<UserManager<User>>();

//            _clientAccessService = new ClientAccessService();

//            var roleManager = _sp.GetRequiredService<RoleManager<IdentityRole>>();
//            if (!await roleManager.RoleExistsAsync("Citizen"))
//                await roleManager.CreateAsync(new IdentityRole("Citizen"));

//            if (!await roleManager.RoleExistsAsync("White collar"))
//                await roleManager.CreateAsync(new IdentityRole("White collar"));

//            if (!await roleManager.RoleExistsAsync("Admin"))
//                await roleManager.CreateAsync(new IdentityRole("Admin"));

//            if (!await roleManager.RoleExistsAsync("Blue collar"))
//                await roleManager.CreateAsync(new IdentityRole("Blue collar"));
//        }

//        private async Task<string> SeedUser(UserController controller)
//        {
//            var email = $"test{Guid.NewGuid()}@email.com";

//            var dto = new RegisterDTO
//            {
//                FirstName = "Arman",
//                LastName = "Rajabi",
//                Email = email,
//                Password = "Test1382@",
//                PasswordConfirm = "Test1382@",
//                RoadNumber = 1,
//                RoadName = "Test",
//                PostalCode = "J1J 1J1",
//                City = "Test"
//            };

//            var res = await controller.Register(dto);
//            Assert.IsInstanceOfType(res, typeof(OkObjectResult));

//            return email;
//        }

//        [TestCleanup]
//        public void Cleanup()
//        {
//            _db.Database.EnsureDeleted();
//            _db.Dispose();
//            _sp.Dispose();
//        }

//        [TestMethod]
//        public async Task RegisterReturnsOk_AndCreatesCitizen()
//        {
//            var controller = new UserController(_userManager, _db, _config, _clientAccessService);

//            var dto = new RegisterDTO
//            {
//                FirstName = "Arman",
//                LastName = "Rajabi",
//                Email = "test@email.com",
//                Password = "Test1382@",
//                PasswordConfirm = "Test1382@",
//                RoadNumber = 1,
//                RoadName = "Test",
//                PostalCode = "J1J 1J1",
//                City = "Test"
//            };

//            var result = await controller.Register(dto);

//            Assert.IsInstanceOfType(result, typeof(OkObjectResult));

//            var saved = await _db.Citizens.FirstOrDefaultAsync();
//            Assert.IsNotNull(saved);
//            Assert.AreEqual("Test", saved.City);
//        }

//        [TestMethod]
//        public async Task Register_BadCredentials()
//        {
//            var controller = new UserController(_userManager, _db, _config, _clientAccessService);

//            var dto = new RegisterDTO
//            {
//                FirstName = "Arman",
//                LastName = "Rajabi",
//                Email = "test@email.com",
//                Password = "Test1382@1",
//                PasswordConfirm = "Test1382@",
//                RoadNumber = 1,
//                RoadName = "Test",
//                PostalCode = "J1J 1J1",
//                City = "Test"
//            };

//            var result = await controller.Register(dto);

//            Assert.IsInstanceOfType(result, typeof(BadRequestObjectResult));

//            var citizensCount = await _db.Citizens.CountAsync();
//            Assert.AreEqual(0, citizensCount);
//        }

//        [TestMethod]
//        public async Task RegisterUserAlreadyExists()
//        {
//            var controller = new UserController(_userManager, _db, _config, _clientAccessService);

//            var dto = new RegisterDTO
//            {
//                FirstName = "Arman",
//                LastName = "Rajabi",
//                Email = "test@email.com",
//                Password = "Test1382@",
//                PasswordConfirm = "Test1382@",
//                RoadNumber = 1,
//                RoadName = "Test",
//                PostalCode = "J1J 1J1",
//                City = "Test"
//            };

//            var first = await controller.Register(dto);
//            Assert.IsInstanceOfType(first, typeof(OkObjectResult));

//            var second = await controller.Register(dto);
//            Assert.IsInstanceOfType(second, typeof(BadRequestObjectResult));

//            var citizensCount = await _db.Citizens.CountAsync();
//            Assert.AreEqual(1, citizensCount);
//        }

//        [TestMethod]
//        public async Task Login_Succesful()
//        {
//            var controller = new UserController(_userManager, _db, _config, _clientAccessService);

//            var email = await SeedUser(controller);

//            controller.ControllerContext = new ControllerContext
//            {
//                HttpContext = new DefaultHttpContext()
//            };
//            controller.HttpContext.Request.Headers["X-Client-Type"] = "web";

//            var dto = new LoginDTO
//            {
//                Username = email,
//                Password = "Test1382@"
//            };

//            var loginResult = await controller.Login(dto);
//            var ok = loginResult as OkObjectResult;
//            Assert.IsNotNull(ok);

//            var json = JsonSerializer.Serialize(ok.Value);
//            Assert.IsTrue(json.Contains("token"));
//        }

//        [TestMethod]
//        public async Task Login_UnSuccesful()
//        {
//            var controller = new UserController(_userManager, _db, _config, _clientAccessService);

//            var email = await SeedUser(controller);

//            controller.ControllerContext = new ControllerContext
//            {
//                HttpContext = new DefaultHttpContext()
//            };
//            controller.HttpContext.Request.Headers["X-Client-Type"] = "web";

//            var dto = new LoginDTO
//            {
//                Username = email,
//                Password = "WrongPass1!"
//            };

//            var loginResult = await controller.Login(dto);
//            var bad = loginResult as BadRequestObjectResult;
//            Assert.IsNotNull(bad);

//            var json = JsonSerializer.Serialize(bad.Value);
//            Assert.IsTrue(json.ToLower().Contains("invalide"));
//        }
//    }
//}
