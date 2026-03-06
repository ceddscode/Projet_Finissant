//using System.Linq.Expressions;
//using Microsoft.AspNetCore.Identity;
//using Microsoft.EntityFrameworkCore;
//using Microsoft.EntityFrameworkCore.Query;
//using Microsoft.VisualStudio.TestTools.UnitTesting;
//using Models.Models;
//using Models.Models.DTOs;
//using Models.Models.Enums;
//using Moq;
//using municipaligo_serveur.Data;
//using WebApi.Services;

//namespace WebApiTests;

//internal class TestAsyncEnumerator<T> : IAsyncEnumerator<T>
//{
//    private readonly IEnumerator<T> _inner;
//    public TestAsyncEnumerator(IEnumerator<T> inner) => _inner = inner;
//    public T Current => _inner.Current;
//    public ValueTask<bool> MoveNextAsync() => new(_inner.MoveNext());
//    public ValueTask DisposeAsync() { _inner.Dispose(); return new ValueTask(); }
//}

//internal class TestAsyncEnumerable<T> : EnumerableQuery<T>, IAsyncEnumerable<T>, IQueryable<T>
//{
//    public TestAsyncEnumerable(IEnumerable<T> enumerable) : base(enumerable) { }
//    public TestAsyncEnumerable(Expression expression) : base(expression) { }
//    IQueryProvider IQueryable.Provider => new TestAsyncQueryProvider<T>(this);
//    public IAsyncEnumerator<T> GetAsyncEnumerator(CancellationToken token = default)
//        => new TestAsyncEnumerator<T>(this.AsEnumerable().GetEnumerator());
//}

//internal class TestAsyncQueryProvider<TEntity> : IQueryProvider, IAsyncQueryProvider
//{
//    private readonly IQueryProvider _inner;
//    public TestAsyncQueryProvider(IQueryProvider inner) => _inner = inner;
//    public IQueryable CreateQuery(Expression expression) => new TestAsyncEnumerable<TEntity>(expression);
//    public IQueryable<TElement> CreateQuery<TElement>(Expression expression) => new TestAsyncEnumerable<TElement>(expression);
//    public object Execute(Expression expression) => _inner.Execute(expression)!;
//    public TResult Execute<TResult>(Expression expression) => _inner.Execute<TResult>(expression);
//    public TResult ExecuteAsync<TResult>(Expression expression, CancellationToken cancellationToken = default)
//    {
//        var resultType = typeof(TResult).GetGenericArguments()[0];
//        var executionResult = Execute(expression);
//        return (TResult)typeof(Task)
//            .GetMethod(nameof(Task.FromResult))!
//            .MakeGenericMethod(resultType)
//            .Invoke(null, new[] { executionResult })!;
//    }
//}

//[TestClass]
//public class IncidentServiceTests
//{
//    private static IncidentService BuildService()
//    {
//        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
//            .UseInMemoryDatabase(Guid.NewGuid().ToString())
//            .Options;
//        var context = new ApplicationDbContext(options);
//        var mockUserManager = new Mock<UserManager<User>>(Mock.Of<IUserStore<User>>(), null, null, null, null, null, null, null, null);
//        var mockNotifications = new Mock<INotificationsService>();
//        return new IncidentService(context, mockUserManager.Object, mockNotifications.Object);
//    }

//    private static IQueryable<Incident> BuildQuery(IEnumerable<Incident> incidents)
//        => new TestAsyncEnumerable<Incident>(incidents);

//    private static Incident MakeIncident(
//        int id,
//        string title = "Test",
//        string location = "Montreal",
//        Status status = Status.WaitingForAssignation,
//        Category category = Category.Mobilier,
//        int likeCount = 0,
//        DateTime? createdAt = null,
//        DateTime? closedAt = null) => new()
//        {
//            Id = id,
//            Title = title,
//            Location = location,
//            Status = status,
//            Categories = category,
//            LikeCount = likeCount,
//            CreatedAt = createdAt ?? DateTime.UtcNow,
//            ClosedAt = closedAt,
//            ImagesUrl = new List<string>()
//        };

//    [TestMethod]
//    public async Task GetSortedIncidents_StripsDateFilters_WhenNotAdmin()
//    {
//        var service = BuildService();
//        var incidents = new[] { MakeIncident(1), MakeIncident(2) };

//        var filter = new QueryParametersDTO
//        {
//            Page = 1,
//            PageSize = 10,
//            DateFrom = DateTime.UtcNow.AddDays(-10),
//            DateEnd = DateTime.UtcNow,
//            FilterByCreation = true
//        };

//        var result = await service.GetSortedIncidents(filter, isAdmin: false, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//        Assert.IsNull(filter.DateFrom, "DateFrom should be stripped for non-admin");
//        Assert.IsNull(filter.DateEnd, "DateEnd should be stripped for non-admin");
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersByCategory_WhenCategoryProvided()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, category: Category.Propreté),
//            MakeIncident(2, category: Category.EspacesVerts),
//            MakeIncident(3, category: Category.Propreté)
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Category = Category.Propreté };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//        Assert.IsTrue(result.Incidents.All(i => i.Category == Category.Propreté));
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_ReturnsAll_WhenNoCategoryFilter()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, category: Category.Propreté),
//            MakeIncident(2, category: Category.Signalisation),
//            MakeIncident(3, category: Category.Social)
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10 };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(3, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersByStatus_WhenStatusProvided()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, status: Status.WaitingForAssignation),
//            MakeIncident(2, status: Status.Done),
//            MakeIncident(3, status: Status.Done)
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Status = Status.Done };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//        Assert.IsTrue(result.Incidents.All(i => i.Status == Status.Done));
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersBySearch_MatchingTitle()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, title: "broken pipe downtown"),
//            MakeIncident(2, title: "fire on main street"),
//            MakeIncident(3, title: "another broken sidewalk")
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Search = "broken" };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersBySearch_MatchingLocation()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, location: "longueuil"),
//            MakeIncident(2, location: "montreal"),
//            MakeIncident(3, location: "longueuil")
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Search = "longueuil" };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_ReturnsAll_WhenSearchIsEmpty()
//    {
//        var service = BuildService();
//        var incidents = new[] { MakeIncident(1), MakeIncident(2), MakeIncident(3) };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Search = "" };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(3, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersByCreationDate_WithDateRange()
//    {
//        var service = BuildService();
//        var baseDate = new DateTime(2025, 1, 15, 0, 0, 0, DateTimeKind.Utc);
//        var incidents = new[]
//        {
//            MakeIncident(1, createdAt: baseDate.AddDays(-5)),
//            MakeIncident(2, createdAt: baseDate),
//            MakeIncident(3, createdAt: baseDate.AddDays(3)),
//            MakeIncident(4, createdAt: baseDate.AddDays(20))
//        };

//        var filter = new QueryParametersDTO
//        {
//            Page = 1,
//            PageSize = 10,
//            DateFrom = baseDate,
//            DateEnd = baseDate.AddDays(5),
//            FilterByCreation = true
//        };

//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersByCreationDate_WithOnlyDateFrom()
//    {
//        var service = BuildService();
//        var baseDate = new DateTime(2025, 1, 10, 0, 0, 0, DateTimeKind.Utc);
//        var incidents = new[]
//        {
//            MakeIncident(1, createdAt: baseDate.AddDays(-1)),
//            MakeIncident(2, createdAt: baseDate),
//            MakeIncident(3, createdAt: baseDate.AddDays(5))
//        };

//        var filter = new QueryParametersDTO
//        {
//            Page = 1,
//            PageSize = 10,
//            DateFrom = baseDate,
//            FilterByCreation = true
//        };

//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_FiltersByClosingDate_WithDateRange()
//    {
//        var service = BuildService();
//        var baseDate = new DateTime(2025, 3, 1, 0, 0, 0, DateTimeKind.Utc);
//        var incidents = new[]
//        {
//            MakeIncident(1, closedAt: baseDate.AddDays(-1)),
//            MakeIncident(2, closedAt: baseDate),
//            MakeIncident(3, closedAt: baseDate.AddDays(2)),
//            MakeIncident(4, closedAt: null)
//        };

//        var filter = new QueryParametersDTO
//        {
//            Page = 1,
//            PageSize = 10,
//            DateFrom = baseDate,
//            DateEnd = baseDate.AddDays(3),
//            FilterByClosing = true,
//            FilterByCreation = false
//        };

//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(2, result.TotalCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_SortsByLikeCount_Descending()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, likeCount: 5),
//            MakeIncident(2, likeCount: 20),
//            MakeIncident(3, likeCount: 1)
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Sort = "LikeCount", Direction = "desc" };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(20, result.Incidents[0].LikeCount);
//        Assert.AreEqual(5, result.Incidents[1].LikeCount);
//        Assert.AreEqual(1, result.Incidents[2].LikeCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_SortsByLikeCount_Ascending()
//    {
//        var service = BuildService();
//        var incidents = new[]
//        {
//            MakeIncident(1, likeCount: 5),
//            MakeIncident(2, likeCount: 20),
//            MakeIncident(3, likeCount: 1)
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10, Sort = "LikeCount", Direction = "asc" };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(1, result.Incidents[0].LikeCount);
//        Assert.AreEqual(5, result.Incidents[1].LikeCount);
//        Assert.AreEqual(20, result.Incidents[2].LikeCount);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_PaginatesCorrectly()
//    {
//        var service = BuildService();
//        var incidents = Enumerable.Range(1, 15).Select(i => MakeIncident(i)).ToArray();

//        var filter = new QueryParametersDTO { Page = 2, PageSize = 5, Sort = "CreatedAt", Direction = "desc" };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(15, result.TotalCount);
//        Assert.AreEqual(5, result.Incidents.Count);
//        Assert.AreEqual(2, result.Page);
//        Assert.AreEqual(5, result.PageSize);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_ReturnsEmpty_WhenPageBeyondResults()
//    {
//        var service = BuildService();
//        var incidents = Enumerable.Range(1, 3).Select(i => MakeIncident(i)).ToArray();

//        var filter = new QueryParametersDTO { Page = 99, PageSize = 10 };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(3, result.TotalCount);
//        Assert.AreEqual(0, result.Incidents.Count);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_MapsDtoFields_Correctly()
//    {
//        var service = BuildService();
//        var createdAt = new DateTime(2025, 5, 1, 0, 0, 0, DateTimeKind.Utc);
//        var closedAt = new DateTime(2025, 6, 1, 0, 0, 0, DateTimeKind.Utc);

//        var incident = new Incident
//        {
//            Id = 42,
//            Title = "Nid de poule",
//            Location = "Rue Sherbrooke",
//            CreatedAt = createdAt,
//            ClosedAt = closedAt,
//            Status = Status.Done,
//            Categories = Category.Saisonnier,
//            LikeCount = 7,
//            ImagesUrl = new List<string> { "http://img1.jpg", "http://img2.jpg" }
//        };

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10 };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(new[] { incident }));

//        var dto = result.Incidents.Single();
//        Assert.AreEqual(42, dto.Id);
//        Assert.AreEqual("Nid de poule", dto.Title);
//        Assert.AreEqual("Rue Sherbrooke", dto.Location);
//        Assert.AreEqual(createdAt, dto.CreatedDate);
//        Assert.AreEqual(closedAt, dto.ClosedDate);
//        Assert.AreEqual(Status.Done, dto.Status);
//        Assert.AreEqual(Category.Saisonnier, dto.Category);
//        Assert.AreEqual(7, dto.LikeCount);
//        Assert.AreEqual("http://img1.jpg", dto.ImageUrl);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_ReturnsEmpty()
//    {
//        var service = BuildService();
//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10 };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(Array.Empty<Incident>()));

//        Assert.AreEqual(0, result.TotalCount);
//        Assert.AreEqual(0, result.Incidents.Count);
//    }

//    [TestMethod]
//    public async Task GetSortedIncidents_NoFilters()
//    {
//        var service = BuildService();
//        var incidents = Enumerable.Range(1, 5).Select(i => MakeIncident(i)).ToArray();

//        var filter = new QueryParametersDTO { Page = 1, PageSize = 10 };
//        var result = await service.GetSortedIncidents(filter, isAdmin: true, BuildQuery(incidents));

//        Assert.AreEqual(5, result.TotalCount);
//    }
//}