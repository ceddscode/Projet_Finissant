using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace Models.Models.DTOs
{
    public class DeviceTokenDTO
    {
    [Required]
    public  string DeviceToken { get; set; }

        public string Language { get; set; } = "fr";

    }
}
