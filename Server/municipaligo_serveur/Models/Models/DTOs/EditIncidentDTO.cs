using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class EditIncidentDTO
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        
        public Category Categories { get; set; }
        
        public int Points { get; set; }

        public List<string> ImagesUrl { get; set; } = new();

        

    }
}
