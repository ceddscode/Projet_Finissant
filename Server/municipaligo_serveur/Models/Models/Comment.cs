using System.Text.Json.Serialization;

namespace Models.Models
{
    public class Comment
    {
        public int Id { get; set; }
        public string Message { get; set; }
        [JsonIgnore]
        public Citizen Citizen { get; set; }
        public int CitizenId { get; set; }
        public int LikeCount { get; set; }
        [JsonIgnore]
        public List<Comment> SubComments { get; set; }
        public int IncidentId { get; set; }
        public int? ParentCommentId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}