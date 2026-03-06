using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.Enums;
using municipaligo_serveur.Data;

namespace WebApi.Services
{
    public class CitizenService
    {
        private ApplicationDbContext _context;

        public CitizenService(ApplicationDbContext context)
        {
            _context = context;
        }

        public bool CitizenExists(int id)
        {
            return _context.Citizens.Any(e => e.Id == id);
        }
        public async Task<Citizen?> GetCitizen(string UserId)
        {
            return await _context.Citizens.Where(i => i.UserId == UserId).FirstOrDefaultAsync();
        }
    }
}
