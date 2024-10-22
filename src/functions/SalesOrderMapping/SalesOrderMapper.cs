using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Linq;

namespace functions.SalesOrderMapping
{
    public class SalesOrderMapping
    {
        private readonly ILogger<SalesOrderMapping> _logger;

        public SalesOrderMapping(ILogger<SalesOrderMapping> logger)
        {
            _logger = logger;
        }

        [Function("SalesOrderMapping")]
        public static async Task<IActionResult> RunAsync([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequest req)
        {
            try
            {
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                var input = JsonConvert.DeserializeObject<SalesOrder>(requestBody);
                var output = new SalesOrder()
                {
                    Name = input.Name,
                    Street = input.Street,
                };
                return new OkObjectResult(output);
            }
            catch (Exception ex)
            {
                return new BadRequestObjectResult(ex.Message);
            }
        }
    }
}
