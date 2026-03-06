using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public record ConversationDto(
        int CitizenId,
        string Name,
        bool Online,
        string LastMessage,
        DateTime LastMessageTime,
        int UnreadCount
    );
}
