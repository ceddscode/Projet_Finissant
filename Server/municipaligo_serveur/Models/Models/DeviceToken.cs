using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NuGet.Packaging;

namespace Models.Models
{
    public class DeviceToken
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public User User { get; set; }
        public string Token { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string Language { get; set; } = "fr";
    }
}
