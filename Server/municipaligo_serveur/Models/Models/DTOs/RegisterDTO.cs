using System.ComponentModel.DataAnnotations;

namespace Models.Models.DTOs
{
    public class RegisterDTO
    {
        [Required(ErrorMessage = "ERR_FIRSTNAME_REQUIRED|Prénom obligatoire.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "ERR_FIRSTNAME_LENGTH|Le prénom doit contenir entre 2 et 50 caractères.")]
        public string FirstName { get; set; } = null!;

        [Required(ErrorMessage = "ERR_PHONE_REQUIRED|Numéro de téléphone obligatoire.")]
        [RegularExpression(@"^(\+1\s?)?(\(?\d{3}\)?[\s\-]?)?\d{3}[\s\-]?\d{4}$",ErrorMessage = "ERR_PHONE_INVALID|Numéro de téléphone invalide.")]
        public string PhoneNumber { get; set; } = null!;

        [Required(ErrorMessage = "ERR_LASTNAME_REQUIRED|Nom obligatoire.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "ERR_LASTNAME_LENGTH|Le nom doit contenir entre 2 et 50 caractères.")]
        public string LastName { get; set; } = null!;

        [Required(ErrorMessage = "ERR_EMAIL_REQUIRED|Courriel obligatoire.")]
        [EmailAddress(ErrorMessage = "ERR_EMAIL_INVALID|Format de courriel invalide.")]
        public string Email { get; set; } = null!;

        [Required(ErrorMessage = "ERR_PASSWORD_REQUIRED|Mot de passe obligatoire.")]
        [MinLength(5, ErrorMessage = "ERR_PASSWORD_LENGTH|Le mot de passe doit contenir au moins 5 caractères.")]
        [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{5,}$",
            ErrorMessage = "ERR_PASSWORD_COMPLEXITY|Le mot de passe doit contenir 1 majuscule, 1 minuscule, 1 chiffre et 1 caractère spécial.")]
        public string Password { get; set; } = null!;

        [Required(ErrorMessage = "ERR_PASSWORDCONFIRM_REQUIRED|Confirmation du mot de passe obligatoire.")]
        [Compare(nameof(Password), ErrorMessage = "ERR_PASSWORD_MISMATCH|Les deux mots de passe ne correspondent pas.")]
        public string PasswordConfirm { get; set; } = null!;

        [Required(ErrorMessage = "ERR_ROADNUMBER_REQUIRED|Numéro de rue obligatoire.")]
        [Range(1, 999999, ErrorMessage = "ERR_ROADNUMBER_RANGE|Numéro de rue invalide.")]
        public int RoadNumber { get; set; }

        [Required(ErrorMessage = "ERR_ROADNAME_REQUIRED|Nom de rue obligatoire.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "ERR_ROADNAME_LENGTH|Le nom de rue doit contenir entre 2 et 100 caractères.")]
        public string RoadName { get; set; } = null!;

        [Required(ErrorMessage = "ERR_POSTAL_REQUIRED|Code postal obligatoire.")]
        [RegularExpression(@"^[A-Za-z]\d[A-Za-z][ ]?\d[A-Za-z]\d$",
            ErrorMessage = "ERR_POSTAL_INVALID|Code postal invalide.")]
        public string PostalCode { get; set; } = null!;

        [Required(ErrorMessage = "ERR_CITY_REQUIRED|Ville obligatoire.")]
        [StringLength(80, MinimumLength = 2, ErrorMessage = "ERR_CITY_LENGTH|La ville doit contenir entre 2 et 80 caractères.")]
        public string City { get; set; } = null!;
    }
}
