const { Router } = require('express');
const router = Router();
const productsController = require('../controllers/products.controller');

router.get('/', productsController.listProducts);
router.put('/:id', productsController.updateProduct);
router.delete('/:id', productsController.deleteProduct);

module.exports = router;
