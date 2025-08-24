using functions.Interface;
using SalesOrder = functions.Model.SalesOrder;
using SalesOrderCdm = functions.Model.SalesOrderCDM;

namespace functions.Mappings
{
    public class SalesOrderToSalesOrderCDM : IMapper<SalesOrder, SalesOrderCdm>
    {
        public Task<SalesOrderCdm> Map(SalesOrder input)
        {
            var output = new SalesOrderCdm()
            {
                Name = input.Name,
                Number = 5,
                Street = input.Street,
            };

            return Task.FromResult(output);
        }
    }
}

