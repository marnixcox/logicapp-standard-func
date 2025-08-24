using Newtonsoft.Json.Serialization;
using Newtonsoft.Json;

namespace functions.Model
{
    [JsonObject(ItemNullValueHandling = NullValueHandling.Ignore, NamingStrategyType = typeof(DefaultNamingStrategy))]
    public class SalesOrder
    {
        public int Number { get; set; }
        public string Name { get; set; }
        public string Street { get; set; }
    }

}
