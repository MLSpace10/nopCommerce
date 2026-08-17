using Microsoft.AspNetCore.Mvc;
using Nop.Plugin.Training.Api.Infrastructure;
using Nop.Plugin.Training.Api.Models;
using Nop.Services.Catalog;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly TrainingFaultState _faultState;

    public ProductsController(IProductService productService, TrainingFaultState faultState)
    {
        _productService = productService;
        _faultState = faultState;
    }

    [HttpGet("/api/products")]
    public async Task<ActionResult<PagedResponse<ProductResponse>>> List(
        [FromQuery] int pageIndex = 0,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (pageIndex < 0 || pageSize is < 1 or > 100)
            return BadRequest(new { code = "invalid_pagination" });

        cancellationToken.ThrowIfCancellationRequested();
        var products = await _productService.SearchProductsAsync(
            pageIndex: pageIndex,
            pageSize: pageSize,
            showHidden: true,
            overridePublished: null);
        cancellationToken.ThrowIfCancellationRequested();

        return Ok(new PagedResponse<ProductResponse>(
            products.Select(Map).ToList(), pageIndex, pageSize, products.TotalCount));
    }

    [HttpGet("/api/products/{productId:int}")]
    public async Task<ActionResult<ProductResponse>> GetById(int productId, CancellationToken cancellationToken)
    {
        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            _faultState.BeforeProductRead();
            var product = await _productService.GetProductByIdAsync(productId);
            return product is null ? NotFound() : Ok(Map(product));
        }
        finally
        {
            Response.Headers["X-Training-Fault-Attempts"] = _faultState.Attempts.ToString();
        }
    }

    private static ProductResponse Map(Nop.Core.Domain.Catalog.Product product)
    {
        return new ProductResponse(product.Id, product.Name, product.Sku, product.Price, product.Published);
    }
}
