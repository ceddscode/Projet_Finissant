using Supabase;

namespace WebApi.Services
{
    public class ImageService
    {

        private readonly Client _storage;

        public ImageService(Client storage) 
        {
            _storage = storage;
        }

        

    }
}
