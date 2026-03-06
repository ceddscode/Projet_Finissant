using System.ComponentModel.DataAnnotations;

namespace Models.Models.DTOs
{
    public class LoginDTO
    {
        [Required(ErrorMessage = "ERR_USERNAME_REQUIRED|Courriel obligatoire.")]
        [EmailAddress(ErrorMessage = "ERR_USERNAME_INVALID|Format de courriel invalide.")]
        public string Username { get; set; } = null!;

        [Required(ErrorMessage = "ERR_PASSWORD_REQUIRED|Mot de passe obligatoire.")]
        public string Password { get; set; } = null!;
    }
}
