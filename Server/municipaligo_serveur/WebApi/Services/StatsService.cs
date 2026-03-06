using System.Globalization;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;
using municipaligo_serveur.Data;

namespace WebApi.Services
{
    public class StatsService
    {
        private readonly UserManager<User> _userManager;
        private ApplicationDbContext _context;
        

        public StatsService(ApplicationDbContext context, UserManager<User> userManager)
        {
            _context = context;
            _userManager = userManager;
            
        }

        public async Task<TimeResultDto> GetAverageResolutionTime(Category? category)
        {
            var query = _context.Incidents
                .Where(i => i.ClosedAt != null && i.CreatedAt != null);

            if (category.HasValue)
                query = query.Where(i => i.Categories == category.Value);

            var data = await query
                .Select(i => (i.ClosedAt!.Value - i.CreatedAt).TotalMinutes)
                .ToListAsync();

            if (!data.Any())
            {
                return new TimeResultDto
                {
                    Value = 0,
                    Unit = "MINUTES"
                };
            }

            var avgMinutes = data
                .Where(x => x >= 0)   // sécurité si données incohérentes
                .DefaultIfEmpty(0)
                .Average();

            // 🔹 Moins de 60 minutes
            if (avgMinutes < 60)
            {
                return new TimeResultDto
                {
                    Value = Math.Round(avgMinutes, 0),
                    Unit = avgMinutes <= 1 ? "MINUTE" : "MINUTES"
                };
            }

            var hours = avgMinutes / 60;

            // 🔹 Moins de 24 heures
            if (hours < 24)
            {
                return new TimeResultDto
                {
                    Value = Math.Round(hours, 1),
                    Unit = hours <= 1 ? "HOUR" : "HOURS"
                };
            }

            var days = hours / 24;

            return new TimeResultDto
            {
                Value = Math.Round(days, 1),
                Unit = days <= 1 ? "DAY" : "DAYS"
            };
        }

        public async Task<TimeResultDto> GetAverageInChargeTime(Category? category)
        {
            var query = _context.Incidents
                .Where(i => i.InProgressAt != null && i.CreatedAt != null);

            if (category.HasValue)
                query = query.Where(i => i.Categories == category.Value);

            var data = await query
                .Select(i => (i.InProgressAt!.Value - i.CreatedAt).TotalMinutes)
                .ToListAsync();

            if (!data.Any())
            {
                return new TimeResultDto
                {
                    Value = 0,
                    Unit = "MINUTES"
                };
            }

            var avgMinutes = data
                .Where(x => x >= 0)   // protection négatif
                .DefaultIfEmpty(0)
                .Average();

            // 🔹 Moins de 60 minutes
            if (avgMinutes < 60)
            {
                return new TimeResultDto
                {
                    Value = Math.Round(avgMinutes, 0),
                    Unit = avgMinutes <= 1 ? "MINUTE" : "MINUTES"
                };
            }

            var hours = avgMinutes / 60;

            // 🔹 Moins de 24 heures
            if (hours < 24)
            {
                return new TimeResultDto
                {
                    Value = Math.Round(hours, 1),
                    Unit = hours <= 1 ? "HOUR" : "HOURS"
                };
            }

            var days = hours / 24;

            return new TimeResultDto
            {
                Value = Math.Round(days, 1),
                Unit = days <= 1 ? "DAY" : "DAYS"
            };
        }

        public async Task<int> GetSolvedIncidentsNumber(Category? category)
        {
            var query = _context.Incidents.AsQueryable();

            if (category.HasValue)
                query = query.Where(i => i.Categories == category.Value);

            return await query
                .Where(i => i.ClosedAt != null)
                .CountAsync();
        }

        public async Task<TimeResultDto> GetAssignmentTime(Category? category)
        {
            var query = _context.Incidents
                .Where(i => i.AssignedAt != null && i.CreatedAt != null);

            if (category.HasValue)
            {
                query = query.Where(i => i.Categories == category.Value);
            }

            // 🔥 On laisse SQL faire juste le calcul simple
            var data = await query
                .Select(i => (i.AssignedAt!.Value - i.CreatedAt).TotalMinutes)
                .ToListAsync();

            if (!data.Any())
            {
                return new TimeResultDto
                {
                    Value = 0,
                    Unit = "MINUTES"
                };
            }

            // 🔥 Maintenant on est en C# pur
            var avgMinutes = data
                .Where(x => x >= 0)   // Protection contre négatif
                .DefaultIfEmpty(0)
                .Average();

            if (avgMinutes < 60)
            {
                return new TimeResultDto
                {
                    Value = Math.Round(avgMinutes, 0),
                    Unit = avgMinutes <= 1 ? "MINUTE" : "MINUTES"
                };
            }

            var hours = avgMinutes / 60;

            if (hours < 24)
            {
                return new TimeResultDto
                {
                    Value = Math.Round(hours, 1),
                    Unit = hours <= 1 ? "HOUR" : "HOURS"
                };
            }

            var days = hours / 24;

            return new TimeResultDto
            {
                Value = Math.Round(days, 1),
                Unit = days <= 1 ? "DAY" : "DAYS"
            };
        }

        public async Task<List<CategoryChartDto>> GetCategoriesChart(string period)
        {
            period = string.IsNullOrWhiteSpace(period) ? "week" : period.ToLower();

            DateTime now = DateTime.UtcNow;

            DateTime startDate = period switch
            {
                "day" => now.AddDays(-1),
                "week" => now.AddDays(-7),
                "month" => now.AddMonths(-1),
                "year" => now.AddYears(-1),
                _ => now.AddDays(-7)
            };

            var data = await _context.Incidents
                .Where(i => i.CreatedAt >= startDate)
                .GroupBy(i => i.Categories)
                .Select(g => new CategoryChartDto
                {
                    Category = g.Key,
                    Count = g.Count()
                })
                .ToListAsync();

            return data;
        }

        public async Task<List<EvolutionChartDto>> GetEvolutionChart(string period)
        {
            DateTime now = DateTime.UtcNow;
            var incidents = _context.Incidents.AsQueryable();

            switch (period)
            {
                case "day":
                    {
                        var start = now.Date;

                        var grouped = await incidents
                            .Where(i => i.CreatedAt >= start)
                            .GroupBy(i => i.CreatedAt.Hour)
                            .Select(g => new { Hour = g.Key, Count = g.Count() })
                            .ToListAsync();

                        return Enumerable.Range(0, 24)
                            .Select(hour => new EvolutionChartDto
                            {
                                Label = $"{hour:00}h",
                                Count = grouped.FirstOrDefault(g => g.Hour == hour)?.Count ?? 0
                            })
                            .ToList();
                    }

                case "week":
                    {
                        var start = now.Date.AddDays(-(int)now.DayOfWeek);

                        var grouped = await incidents
                            .Where(i => i.CreatedAt >= start)
                            .GroupBy(i => i.CreatedAt.DayOfWeek)
                            .Select(g => new { Day = g.Key, Count = g.Count() })
                            .ToListAsync();

                        return Enum.GetValues<DayOfWeek>()
                            .Select(day => new EvolutionChartDto
                            {
                                Label = day.ToString(),
                                Count = grouped.FirstOrDefault(g => g.Day == day)?.Count ?? 0
                            })
                            .ToList();
                    }

                case "month":
                    {
                        var currentYear = now.Year;

                        var grouped = await incidents
                            .Where(i => i.CreatedAt.Year == currentYear)
                            .GroupBy(i => i.CreatedAt.Month)
                            .Select(g => new { Month = g.Key, Count = g.Count() })
                            .ToListAsync();

                        return Enumerable.Range(1, 12)
                            .Select(month => new EvolutionChartDto
                            {
                                Label = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(month),
                                Count = grouped.FirstOrDefault(g => g.Month == month)?.Count ?? 0
                            })
                            .ToList();
                    }

                case "year":
                    {
                        var grouped = await incidents
                            .GroupBy(i => i.CreatedAt.Year)
                            .Select(g => new EvolutionChartDto
                            {
                                Label = g.Key.ToString(),
                                Count = g.Count()
                            })
                            .OrderBy(x => x.Label)
                            .ToListAsync();

                        return grouped;
                    }

                default:
                    return new List<EvolutionChartDto>();
            }
        }
    }


    
}
