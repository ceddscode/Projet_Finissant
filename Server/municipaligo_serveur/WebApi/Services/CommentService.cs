using System.Xml.Linq;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.DTOs;
using municipaligo_serveur.Data;
using WebApi.Interfaces;

namespace WebApi.Services
{
    public class CommentService
    {
        private readonly UserManager<User> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly CitizenService _citizenService;
        private readonly IIncidentService _incidentService;

        public CommentService(ApplicationDbContext context, UserManager<User> userManager, IIncidentService incidentService, CitizenService citizenService)
        {
            _context = context;
            _userManager = userManager;
            _incidentService = incidentService;
            _citizenService = citizenService;
        }

        public async Task<bool> CommentExists(int? commentId)
        {
            return await _context.Comments.AnyAsync(x => x.Id == commentId);
        }

        public async Task<bool> IsCitizenOwner(int citizenId, int commentId)
        {
            return await _context.Comments.AnyAsync(x => x.Id == commentId && x.CitizenId == citizenId);
        }

        public async Task<Comment?> GetComment(int commentId)
        {
            return await _context.Comments.Where(i => i.Id == commentId).FirstOrDefaultAsync();
        }

        public async Task<bool> ToggleLikeComment(int commentId, string userId)
        {
            var comment = await GetComment(commentId);
            var citizen = await _citizenService.GetCitizen(userId);     

            if (comment == null || citizen == null)
                return false;

            var existing = await _context.LikedComments.FirstOrDefaultAsync(i => i.CommentId == commentId && i.CitizenId == citizen.Id);

            if (existing != null)
            {
                _context.LikedComments.Remove(existing);
                comment.LikeCount--;
            }
            else
            {
                _context.LikedComments.Add(new LikedComment
                {
                    CitizenId = citizen.Id,
                    CommentId = commentId,
                });
                comment.LikeCount++;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<CommentDTO?> PostComment(int incidentId, string message, string userId, int? commentId)
        {
            var citizen = await _citizenService.GetCitizen(userId);
            var incident = await _incidentService.GetIncident(incidentId);
            var parentComment = await CommentExists(commentId);

            if (citizen == null || incident == null)
                return null;

            if (commentId.HasValue && !parentComment)
                commentId = null;

            var comment = new Comment
            {
                CitizenId = citizen.Id,
                Message = message,
                LikeCount = 0,
                IncidentId = incident.Id,
                SubComments = new List<Comment>(),
                ParentCommentId = commentId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Comments.Add(comment);
            await _context.SaveChangesAsync();

            return new CommentDTO
            {
                Id = comment.Id,
                LikeCount = comment.LikeCount,
                Message = comment.Message,
                CitizenName = citizen.FirstName + " " + citizen.LastName,
                IsLiked = false
            };
        }

        public async Task<List<CommentDTO>?> GetComments(int incidentId, int page, int pageSize, string userId)
        {
            var incidentExists = await _incidentService.IncidentExists(incidentId);
            var citizen = await _citizenService.GetCitizen(userId);

            if (!incidentExists || citizen == null)
                return null;

            var comments = await _context.Comments
                .Include(i => i.Citizen)
                .Include(i => i.SubComments)
                .Where(i => i.IncidentId == incidentId && i.ParentCommentId == null)
                .OrderByDescending(c => c.CreatedAt)
                .ThenByDescending(c => c.LikeCount)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var commentIds = comments.Select(c => c.Id).ToList();

            var likedIds = await _context.LikedComments
                .Where(l => l.CitizenId == citizen.Id && commentIds.Contains(l.CommentId))
                .Select(l => l.CommentId)
                .ToListAsync();

            // Récupérer le nombre de reports pour chaque commentaire
            var reports = await _context.ReportComments
                .Where(r => commentIds.Contains(r.CommentId))
                .GroupBy(r => r.CommentId)
                .Select(g => new { CommentId = g.Key, Count = g.Count() })
                .ToListAsync();

            return comments.Select(i => new CommentDTO
            {
                Id = i.Id,
                LikeCount = i.LikeCount,
                Message = i.Message,
                CitizenName = i.Citizen.FirstName + ' ' + i.Citizen.LastName,
                IsLiked = likedIds.Contains(i.Id),
                RepliesCount = i.SubComments.Count,
                IsOwner = i.CitizenId == citizen.Id,
                ReportsCount = reports.FirstOrDefault(r => r.CommentId == i.Id)?.Count ?? 0
            }).ToList();
        }
        public async Task<List<CommentDTO>?> GetReplies(int commentId, int page, int pageSize, string userId)
        {
            var commentExists = await CommentExists(commentId);
            var citizen = await _citizenService.GetCitizen(userId);

            if (!commentExists || citizen == null)
                return null;

            var commentIds = _context.Comments.Select(c => c.Id).ToList();

            var likedIds = await _context.LikedComments
                .Where(l => l.CitizenId == citizen.Id && commentIds.Contains(l.CommentId))
                .Select(l => l.CommentId)
                .ToListAsync();

            return await _context.Comments
                .Include(i => i.Citizen)
                .Where(i => i.ParentCommentId == commentId)
                .OrderByDescending(c => c.CreatedAt)
                .ThenByDescending(c => c.LikeCount)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(i => new CommentDTO
                {
                    Id = i.Id,
                    LikeCount = i.LikeCount,
                    Message = i.Message,
                    CitizenName = i.Citizen.FirstName + ' ' + i.Citizen.LastName,
                    IsLiked = likedIds.Contains(i.Id),
                    IsOwner = i.CitizenId == citizen.Id
                })
                .ToListAsync();
        }

        public async Task<bool> DeleteComment(int commentId, string userId)
        {
            var commentExists = await CommentExists(commentId);
            var citizen = await _citizenService.GetCitizen(userId);

            if (!commentExists || citizen == null)
                return false;

            var isOwner = await IsCitizenOwner(citizen.Id, commentId);

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return false;

            var roles = await _userManager.GetRolesAsync(user);
            var canDelete = isOwner || roles.Contains("White collar") || roles.Contains("Admin");

            if (!canDelete)
                return false;

            await _context.Comments.Where(x => x.ParentCommentId == commentId).ExecuteDeleteAsync();
            await _context.Comments.Where(x => x.Id == commentId).ExecuteDeleteAsync();

            return true;
        }

        public async Task<bool> ReportComment(int commentId, string userId)
        {
            var commentExists = await CommentExists(commentId);
            var citizen = await _citizenService.GetCitizen(userId);

            if (!commentExists || citizen == null)
                return false;

            var alreadyReported = await _context.ReportComments
                .AnyAsync(r => r.CommentId == commentId && r.CitizenId == citizen.Id);
            if (alreadyReported)
                return false;

            _context.ReportComments.Add(new ReportComment
            {
                CommentId = commentId,
                CitizenId = citizen.Id,
            });

            await _context.SaveChangesAsync();
            return true;
        }
    }
}
