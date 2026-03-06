using System.Text;
using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.DTOs;
using municipaligo_serveur.Data;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using WebApi.Interfaces;

namespace WebApi.Services
{
    public class ExportService
    {
        private readonly ApplicationDbContext _context;
        private readonly IIncidentService _incidentService;

        public ExportService(ApplicationDbContext context, IIncidentService incidentService)
        {
            _context = context;
            _incidentService = incidentService;
        }
        private IQueryable<Incident> BuildSortedIncidentsQuery(QueryParametersDTO filter, bool isAdmin, IQueryable<Incident>? baseQuery = null)
        {
            if (!isAdmin)
            {
                filter.DateEnd = null;
                filter.DateFrom = null;
                filter.ClosingDate = null;
                filter.CreationDate = null;
            }

            if (filter.DateFrom.HasValue)
                filter.DateFrom = DateTime.SpecifyKind(filter.DateFrom.Value, DateTimeKind.Utc);
            if (filter.DateEnd.HasValue)
                filter.DateEnd = DateTime.SpecifyKind(filter.DateEnd.Value, DateTimeKind.Utc);

            var query = baseQuery ?? _context.Incidents.AsNoTracking().AsQueryable();

            if (filter.Category.HasValue)
                query = query.Where(t => t.Categories == filter.Category);

            if (filter.Status.HasValue)
                query = query.Where(t => t.Status == filter.Status);

            if (!string.IsNullOrWhiteSpace(filter.Search))
            {
                var term = filter.Search.Trim().ToLower();
                query = query.Where(t =>
                    t.Title.ToLower().Contains(term) ||
                    t.Location.ToLower().Contains(term)
                );
            }

            if (filter.DateFrom.HasValue || filter.DateEnd.HasValue)
            {
                if (filter.FilterByCreation)
                {
                    if (filter.DateFrom.HasValue)
                        query = query.Where(t => t.CreatedAt >= filter.DateFrom.Value);
                    if (filter.DateEnd.HasValue)
                        query = query.Where(t => t.CreatedAt < filter.DateEnd.Value.AddDays(1));
                }
                else if (filter.FilterByClosing)
                {
                    if (filter.DateFrom.HasValue)
                        query = query.Where(t => t.ClosedAt.HasValue && t.ClosedAt.Value >= filter.DateFrom.Value);
                    if (filter.DateEnd.HasValue)
                        query = query.Where(t => t.ClosedAt.HasValue && t.ClosedAt.Value < filter.DateEnd.Value.AddDays(1));
                }
            }

            query = filter.Sort switch
            {
                "ClosedAt" => filter.Direction == "asc" ? query.OrderBy(e => e.ClosedAt) : query.OrderByDescending(e => e.ClosedAt),
                "Categories" => filter.Direction == "asc" ? query.OrderBy(e => e.Categories) : query.OrderByDescending(e => e.Categories),
                "Status" => filter.Direction == "asc" ? query.OrderBy(e => e.Status) : query.OrderByDescending(e => e.Status),
                "LikeCount" => filter.Direction == "asc" ? query.OrderBy(e => e.LikeCount) : query.OrderByDescending(e => e.LikeCount),
                _ => filter.Direction == "asc" ? query.OrderBy(e => e.CreatedAt) : query.OrderByDescending(e => e.CreatedAt),
            };

            return query;
        }

        public async Task<PagedResult<SortedIncidentsDTO>> GetSortedIncidents(
            QueryParametersDTO filter,
            bool isAdmin,
            IQueryable<Incident>? baseQuery = null)
        {
            var query = BuildSortedIncidentsQuery(filter, isAdmin, baseQuery);

            var totalCount = await query.CountAsync();

            var incidents = await query
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(t => new SortedIncidentsDTO(t))
                .ToListAsync();

            return new PagedResult<SortedIncidentsDTO>
            {
                Incidents = incidents,
                TotalCount = totalCount,
                Page = filter.Page,
                PageSize = filter.PageSize
            };
        }

        public async Task<List<IncidentListDTO>> GetSortedIncidentsForExport(
            QueryParametersDTO filter,
            bool isAdmin,
            IQueryable<Incident>? baseQuery = null)
        {
            var query = BuildSortedIncidentsQuery(filter, isAdmin, baseQuery);

            return await query
                .Select(t => new IncidentListDTO
                {
                    Id = t.Id,
                    Title = t.Title,
                    Location = t.Location,
                    CreatedAt = t.CreatedAt,
                    Status = t.Status,
                    ImagesUrl=t.ImagesUrl
                })
                .ToListAsync();
        }

        public byte[] ExportPDF(List<IncidentListDTO> incidents)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            IContainer Cell(IContainer c) =>
                c.Border(1)
                 .BorderColor(Colors.Grey.Lighten2)
                 .PaddingVertical(4)
                 .PaddingHorizontal(6)
                 .AlignMiddle();

            var doc = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(20);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    page.Header().Text("Liste des Incidents").SemiBold().FontSize(16);

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.ConstantColumn(30);    // ID
                            columns.RelativeColumn(2);     // Title
                            columns.RelativeColumn(4);     // Location (wider)
                            columns.ConstantColumn(70);    // Date
                            columns.RelativeColumn(2);
                            columns.ConstantColumn(70);  
                        });

                        table.Header(h =>
                        {
                            h.Cell().Element(Cell).Text("ID").SemiBold();
                            h.Cell().Element(Cell).Text("Title").SemiBold();
                            h.Cell().Element(Cell).Text("Location").SemiBold();
                            h.Cell().Element(Cell).Text("Created At").SemiBold();
                            h.Cell().Element(Cell).Text("Status").SemiBold();
                            h.Cell().Element(Cell).Text("ImagesUrl").SemiBold();
                        });

                        foreach (var i in incidents)
                        {
                            table.Cell().Element(Cell).Text(i.Id.ToString());

                            table.Cell().Element(Cell).Text(t =>
                            {
                                t.Span(i.Title ?? "").WrapAnywhere();
                            });

                            table.Cell().Element(Cell).Text(t =>
                            {
                                t.Span(i.Location ?? "").WrapAnywhere();
                            });

                            table.Cell().Element(Cell).Text(i.CreatedAt.ToString("yyyy-MM-dd"));

                            table.Cell().Element(Cell).Text(t =>
                            {
                                t.Span(i.Status.ToString()).WrapAnywhere();
                            });
                            table.Cell().Element(Cell).Text(t =>
                            {
                                t.Span(string.Join(" | ", i.ImagesUrl ?? new List<string>())).WrapAnywhere();
                            });
                        }
                    });
                });
            });

            return doc.GeneratePdf();
        }
        public async Task<byte[]> ExportPDF(QueryParametersDTO filter,bool isAdmin)
        {
            var incident = await GetSortedIncidentsForExport(filter, isAdmin);

            return ExportPDF(incident);
        }
        public async Task<byte[]> ExportExcel(QueryParametersDTO filter, bool isAdmin)
        {
            using var wb = new XLWorkbook();
            var ws = wb.Worksheets.Add("Incidents");

            ws.Cell(1, 1).Value = "Id";
            ws.Cell(1, 2).Value = "Title";
            ws.Cell(1, 4).Value = "Location";
            ws.Cell(1, 5).Value = "CreatedAt";
            ws.Cell(1, 6).Value = "Status";
            ws.Cell(1, 7).Value = "ImagesUrl";
            var incident = await GetSortedIncidentsForExport(filter, isAdmin);

            for (int i = 0; i < incident.Count; i++)
            {
                var r = i + 2;
                var inc = incident[i];

                ws.Cell(r, 1).Value = inc.Id;
                ws.Cell(r, 2).Value = inc.Title ?? "";
                ws.Cell(r, 4).Value = inc.Location ?? "";
                ws.Cell(r, 5).Value = inc.CreatedAt;
                ws.Cell(r, 6).Value = inc.Status.ToString();
                ws.Cell(r, 7).Value = string.Join(" | ", inc.ImagesUrl ?? new List<string>());
            }

            ws.Columns().AdjustToContents();

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        public async Task<byte[]> ExportCSV(QueryParametersDTO filter, bool isAdmin)
        {
            var incidents = await GetSortedIncidentsForExport(filter, isAdmin);

            var sb = new StringBuilder();
            sb.AppendLine("Id,Title,Location,CreatedAt,Status");

            foreach (var i in incidents)
            {
                sb.AppendLine(string.Join(",",
                    Csv(i.Id.ToString()),
                    Csv(i.Title),
                    Csv(i.Location),
                    Csv(i.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ssZ")),
                    Csv(i.Status.ToString()),
                    Csv(string.Join(" | ", i.ImagesUrl ?? new List<string>()))
                ));
            }

            var utf8Bom = new UTF8Encoding(true);
            return utf8Bom.GetBytes(sb.ToString());
        }

        private static string Csv(string? value)
        {
            value ??= "";
            value = value.Replace("\"", "\"\"");
            return $"\"{value}\"";
        }

        public async Task<byte[]> ExportJson(QueryParametersDTO filter, bool isAdmin)
        {
            var incidents = await GetSortedIncidentsForExport(filter, isAdmin);
            var json = System.Text.Json.JsonSerializer.Serialize(incidents, new System.Text.Json.JsonSerializerOptions
            {
                WriteIndented = true
            });

            var bytes = System.Text.Encoding.UTF8.GetBytes(json);
            return bytes;
        }

    }

}