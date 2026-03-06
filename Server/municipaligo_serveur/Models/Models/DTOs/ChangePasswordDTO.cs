using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
    using System.Text.Json.Serialization;

namespace Models.Models.DTOs
{

    public class ChangePasswordDTO
    {
        [JsonPropertyName("currentPassword")]
        public string CurrentPassword { get; set; } = "";

        [JsonPropertyName("newPassword")]
        public string NewPassword { get; set; } = "";

        [JsonPropertyName("confirmNewPassword")]
        public string ConfirmNewPassword { get; set; } = "";
    }
}
