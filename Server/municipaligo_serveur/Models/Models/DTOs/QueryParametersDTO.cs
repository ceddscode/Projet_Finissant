using System;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class QueryParametersDTO
    {
        public Category? Category { get; set; }
        public Status? Status { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateEnd { get; set; }
        public DateTime? CreationDate { get; set; }
        public DateTime? ClosingDate { get; set; }
        public bool FilterByCreation { get; set; } = true;
        public bool FilterByClosing { get; set; } = false;
        public string? Sort { get; set; }
        public string? Direction { get; set; } = "desc";
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
        public string? Search { get; set; }
    }
}