using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public record CitizenDTO(
        int Id,
        string Name,
        bool Online
    );
}
