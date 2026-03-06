using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.DTOs;
using municipaligo_serveur.Data;

public class BadgeService
{
    private readonly ApplicationDbContext _context;

    public BadgeService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task CheckLevelUpAsync(int citizenId)
    {
        var citizen = await _context.Citizens
            .Include(c => c.CitizenBadges)
            .FirstOrDefaultAsync(c => c.Id == citizenId);

        if (citizen == null)
            return;

        var allBadges = await _context.Badges
            .OrderBy(b => b.MinPointsRequired)
            .ToListAsync();

        foreach (var badge in allBadges)
        {
            if (citizen.Points >= badge.MinPointsRequired)
            {
                bool alreadyHas = citizen.CitizenBadges
                    .Any(cb => cb.BadgeId == badge.Id);

                if (!alreadyHas)
                {
                    _context.CitizenBadges.Add(new CitizenBadge
                    {
                        CitizenId = citizen.Id,
                        BadgeId = badge.Id,
                        EarnedAt = DateTime.UtcNow
                    });
                }
            }
        }

        await _context.SaveChangesAsync();
    }

    public async Task<CitizenBadgeProfileDTO?> GetCitizenBadgeProfile(string userId)
    {
        var citizen = await _context.Citizens
            .Include(c => c.CitizenBadges)
            .ThenInclude(cb => cb.Badge)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (citizen == null)
            return null;

        var allBadges = await _context.Badges
            .OrderBy(b => b.MinPointsRequired)
            .ToListAsync();

        var currentLevel = allBadges
            .Where(b => citizen.Points >= b.MinPointsRequired)
            .OrderByDescending(b => b.MinPointsRequired)
            .FirstOrDefault();

        var nextLevel = allBadges
            .Where(b => b.MinPointsRequired > citizen.Points)
            .OrderBy(b => b.MinPointsRequired)
            .FirstOrDefault();

        int progress = 100;

        if (nextLevel != null && currentLevel != null)
        {
            int range = nextLevel.MinPointsRequired - currentLevel.MinPointsRequired;
            int gained = citizen.Points - currentLevel.MinPointsRequired;

            progress = range == 0 ? 100 : (gained * 100) / range;
        }

        return new CitizenBadgeProfileDTO
        {
            Points = citizen.Points,
            CurrentLevelName = currentLevel?.Name ?? "",
            CurrentLevelMinPoints = currentLevel?.MinPointsRequired ?? 0,
            NextLevelMinPoints = nextLevel?.MinPointsRequired,
            ProgressPercentage = progress,
            Badges = citizen.CitizenBadges
                .OrderBy(cb => cb.Badge.MinPointsRequired)
                .Select(cb => new BadgeDTO
                {
                    Id = cb.Badge.Id,
                    Name = cb.Badge.Name,
                    ImageUrl = cb.Badge.ImageUrl,
                    EarnedAt = cb.EarnedAt
                })
                .ToList()
        };
    }
}