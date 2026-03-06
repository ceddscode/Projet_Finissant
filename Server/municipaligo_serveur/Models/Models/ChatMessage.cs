namespace Models.Models
{
    public class ChatMessage
    {
        public int Id { get; set; }
        public int FromCitizenId { get; set; }
        public int ToCitizenId { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime SentAt { get; set; } = DateTime.UtcNow;
        public bool Read { get; set; } = false;
        public Citizen FromCitizen { get; set; } = null!;
        public Citizen ToCitizen { get; set; } = null!;
        public int? SharedIncidentId { get; set; }
        public Incident? Incident { get; set; }
    }
}
