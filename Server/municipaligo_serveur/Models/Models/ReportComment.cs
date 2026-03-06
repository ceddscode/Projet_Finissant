using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Models.Models
{
    public class ReportComment
    {
        public int Id { get; set; }
        public int CommentId { get; set; }
        public int CitizenId { get; set; }
        [JsonIgnore]
        public Citizen Citizen { get; set; }
    }
}
