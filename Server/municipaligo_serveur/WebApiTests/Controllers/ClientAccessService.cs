using Microsoft.VisualStudio.TestTools.UnitTesting;
using WebApi.Services;

namespace WebApi.Services.Tests
{
    [TestClass]
    public class ClientAccessServiceTests
    {
        private ClientAccessService _sut = null!;

        [TestInitialize]
        public void Setup()
        {
            _sut = new ClientAccessService();
        }

        [TestMethod]
        public void Citizen_Allows_Flutter()
        {
            var ok = _sut.isAllowed(new[] { "Citizen" }, "flutter");
            Assert.IsTrue(ok);
        }

        [TestMethod]
        public void Citizen_Denies_Web()
        {
            var ok = _sut.isAllowed(new[] { "Citizen" }, "web");
            Assert.IsFalse(ok);
        }

        [TestMethod]
        public void Admin_Allows_Web()
        {
            var ok = _sut.isAllowed(new[] { "Admin" }, "web");
            Assert.IsTrue(ok);
        }

        [TestMethod]
        public void Admin_Denies_Flutter()
        {
            var ok = _sut.isAllowed(new[] { "Admin" }, "flutter");
            Assert.IsFalse(ok);
        }

        [TestMethod]
        public void WhiteCollar_Allows_Web()
        {
            var ok = _sut.isAllowed(new[] { "White collar" }, "web");
            Assert.IsTrue(ok);
        }

        [TestMethod]
        public void WhiteCollar_Denies_Flutter()
        {
            var ok = _sut.isAllowed(new[] { "White collar" }, "flutter");
            Assert.IsFalse(ok);
        }

        [TestMethod]
        public void BlueCollar_Allows_Flutter()
        {
            var ok = _sut.isAllowed(new[] { "Blue collar" }, "flutter");
            Assert.IsTrue(ok);
        }

        [TestMethod]
        public void BlueCollar_Denies_Web()
        {
            var ok = _sut.isAllowed(new[] { "Blue collar" }, "web");
            Assert.IsFalse(ok);
        }

        [TestMethod]
        public void MultipleRoles_AllAllowed_ReturnsTrue()
        {
            var ok = _sut.isAllowed(new[] { "Citizen", "Blue collar" }, "flutter");
            Assert.IsTrue(ok);
        }

        [TestMethod]
        public void MultipleRoles_OneNotAllowed_ReturnsFalse()
        {
            var ok = _sut.isAllowed(new[] { "Citizen", "Admin" }, "flutter");
            Assert.IsFalse(ok);
        }

        [TestMethod]
        public void UnknownRole_ReturnsFalse()
        {
            var ok = _sut.isAllowed(new[] { "RandomRole" }, "flutter");
            Assert.IsFalse(ok);
        }

        [TestMethod]
        public void EmptyRoles_ReturnsTrue()
        {
            var ok = _sut.isAllowed(System.Array.Empty<string>(), "flutter");
            Assert.IsTrue(ok);
        }

        [TestMethod]
        public void ClientType_IsCaseSensitive_FlutterVsFLUTTER()
        {
            var ok = _sut.isAllowed(new[] { "Citizen" }, "FLUTTER");
            Assert.IsFalse(ok);
        }
    }
}
