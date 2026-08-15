using Microsoft.AspNetCore.Mvc;
using Nop.Plugin.Training.Api.Models;
using Nop.Services.Catalog;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class InventoryController : ControllerBase
{
    private readonly IProductService _productService;

    public InventoryController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet("/api/inventory/{productId:int}")]
    public async Task<ActionResult<InventoryResponse>> Get(int productId, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var product = await _productService.GetProductByIdAsync(productId);
        if (product is null)
            return NotFound();

        var quantity = await _productService.GetTotalStockQuantityAsync(product);
        return Ok(new InventoryResponse(product.Id, product.ManageInventoryMethod.ToString(), quantity));
    }
}
