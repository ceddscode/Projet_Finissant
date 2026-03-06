using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class CategoryChartDto
    {
        public Category Category { get; set; }
        public int Count { get; set; }
    }
}
