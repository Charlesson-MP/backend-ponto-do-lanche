const productsService = require('../services/products.service');

const listProducts = async (req, res, next) => {
  try {
    const products = await productsService.listProducts();
    return res.json({ success: true, data: products });
  } catch (err) {
    next(err);
  }
};

const updateProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { price } = req.body;

    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });
    if (price === undefined) return res.status(400).json({ success: false, message: 'Price is required' });

    const updatedProduct = await productsService.updateProductPrice(id, price);

    if (!updatedProduct) {
      return res.status(404).json({ success: false, message: 'Produto não encontrado.' });
    }

    return res.json({ success: true, data: updatedProduct });
  } catch (err) {
    next(err);
  }
};

const deleteProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const deletedProduct = await productsService.deleteProduct(id);

    if (!deletedProduct) {
      return res.status(404).json({ success: false, message: 'Produto não encontrado.' });
    }

    return res.json({ success: true, message: 'Produto removido com sucesso' });
  } catch (err) {
    if (err.code === '23503') { // foreign_key_violation
      return res.status(400).json({ success: false, message: 'Não é possível remover produto vinculado a um pedido.' });
    }
    next(err);
  }
};

module.exports = {
  listProducts,
  updateProduct,
  deleteProduct
};
