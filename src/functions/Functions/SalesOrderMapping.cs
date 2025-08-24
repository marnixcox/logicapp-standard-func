using functions.Interface;
using functions.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using FromBodyAttribute = Microsoft.Azure.Functions.Worker.Http.FromBodyAttribute;

namespace functions.Functions
{
    public class SalesOrderMapping
    {
        private readonly ILogger<SalesOrderMapping> _logger;
        private readonly IMapper<SalesOrder, SalesOrderCDM> _mapper;

        public SalesOrderMapping(IMapper<SalesOrder, SalesOrderCDM> mapper, ILogger<SalesOrderMapping> logger)
        {
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [Function(nameof(SalesOrderMapping))]
        public async Task<IActionResult> RunAsync(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]
        HttpRequest request,
        [FromBody] SalesOrder input)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            try
            {
                if (input == null)
                {
                    return new BadRequestObjectResult(new { error = "Invalid input." });
                }

                var output = await _mapper.Map(input);
                return new OkObjectResult(output);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception in mapping - {FunctionName}", nameof(SalesOrderMapping));
                return new BadRequestObjectResult(new { error = ex.Message });
            }
        }
    }
}
