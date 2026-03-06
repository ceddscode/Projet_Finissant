using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public class CommentDTO
    {
        public int Id { get; set; }
        public string Message { get; set; }
        public int LikeCount { get; set; }
        public string CitizenName { get; set; }
        public bool IsLiked { get; set; }
        public int RepliesCount { get; set; }
        public bool IsOwner { get; set; }
        public bool IsReported { get; set; }
        public int ReportsCount { get; set; }

    }
}
