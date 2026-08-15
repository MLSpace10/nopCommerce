using Microsoft.AspNetCore.Mvc;
using Nop.Plugin.Training.Api.Models;
using Nop.Services.Customers;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class CustomersController : ControllerBase
{
    private readonly ICustomerService _customerService;

    public CustomersController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    [HttpGet("/api/customers")]
    public async Task<ActionResult<PagedResponse<CustomerResponse>>> List(
        [FromQuery] int pageIndex = 0,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (pageIndex < 0 || pageSize is < 1 or > 100)
            return BadRequest(new { code = "invalid_pagination" });

        cancellationToken.ThrowIfCancellationRequested();
        var customers = await _customerService.GetAllCustomersAsync(pageIndex: pageIndex, pageSize: pageSize);
        cancellationToken.ThrowIfCancellationRequested();

        return Ok(new PagedResponse<CustomerResponse>(
            customers.Select(Map).ToList(), pageIndex, pageSize, customers.TotalCount));
    }

    [HttpGet("/api/customers/{customerId:int}")]
    public async Task<ActionResult<CustomerResponse>> GetById(int customerId, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var customer = await _customerService.GetCustomerByIdAsync(customerId);
        return customer is null ? NotFound() : Ok(Map(customer));
    }

    private static CustomerResponse Map(Nop.Core.Domain.Customers.Customer customer)
    {
        return new CustomerResponse(customer.Id, customer.Email, customer.Active, customer.CreatedOnUtc, customer.BillingAddressId);
    }
}
