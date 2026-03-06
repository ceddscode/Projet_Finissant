using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models
{
    public class IncidentLike
    {
        public int Id { get; set; }
        public int IncidentId { get; set; }
        public int CitizenId { get; set; }
    }
}
