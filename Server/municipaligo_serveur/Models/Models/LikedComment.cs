using System.Text.Json.Serialization;

namespace Models.Models
{
    public class LikedComment
    {
        public int Id { get; set; }
        public int CommentId { get; set; }
        public int CitizenId { get; set; }
        [JsonIgnore]
        public Citizen Citizen { get; set; }
    }
}
