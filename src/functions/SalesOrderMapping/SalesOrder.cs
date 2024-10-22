using Newtonsoft.Json.Serialization;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace functions.SalesOrderMapping
{
    [JsonObject(ItemNullValueHandling = NullValueHandling.Ignore, NamingStrategyType = typeof(DefaultNamingStrategy))]
    public class SalesOrder
    {
        public int Number { get; set; }
        public string Name { get; set; }
        public string Street { get; set; }
    }

}
