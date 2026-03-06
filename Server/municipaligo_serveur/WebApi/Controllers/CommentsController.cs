using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Models.Models;
using Models.Models.DTOs;
using municipaligo_serveur.Data;
using WebApi.Interfaces;
using WebApi.Services;

namespace WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class CommentsController : ControllerBase
    {
        private readonly CommentService _commentService;

        public CommentsController(CommentService commentService)
        {
            _commentService = commentService;
        }

        [HttpPost("PostComment")]
        public async Task<ActionResult<CommentDTO>> PostComment(int incidentId, string message, int? commentId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            var comment = await _commentService.PostComment(incidentId, message, userId, commentId);

            if (comment == null)
                return NotFound();

            return Ok(comment);
        }

        [HttpGet("GetComments")]
        public async Task<ActionResult<List<CommentDTO>>> GetComments(int incidentId, int page, int pageSize)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            var comments = await _commentService.GetComments(incidentId, page, pageSize, userId);

            if (comments == null)
                return NotFound();

            return Ok(comments);
        }

        [HttpGet("GetReplies")]
        public async Task<ActionResult<List<CommentDTO>>> GetReplies(int commentId, int page, int pageSize)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            var replies = await _commentService.GetReplies(commentId, page, pageSize, userId);

            if (replies == null)
                return NotFound();

            return Ok(replies);
        }

        [HttpPut("ToggleLikeComment")]
        public async Task<IActionResult> ToggleLikeComment(int commentId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            var success = await _commentService.ToggleLikeComment(commentId, userId);

            if (!success)
                return NotFound();

            return Ok();
        }

        [HttpDelete("DeleteComment")]
        public async Task<IActionResult> DeleteComment(int commentId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            var success = await _commentService.DeleteComment(commentId, userId);

            if (!success)
                return NotFound();

            return Ok();
        }

        [HttpPost("ReportComment")]
        public async Task<IActionResult> ReportComment(int commentId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userId == null)
                return Unauthorized();

            var success = await _commentService.ReportComment(commentId, userId);

            if (!success)
                return NotFound();

            return Ok();
        }
    }
}
