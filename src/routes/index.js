const { Router } = require('express');
const router = Router();

const storeSettingsRoutes = require('./store-settings.routes');
const categoriesRoutes = require('./categories.routes');
const productsRoutes = require('./products.routes');
const customersRoutes = require('./customers.routes');
const ordersRoutes = require('./orders.routes');

router.use('/store-settings', storeSettingsRoutes);
router.use('/categories', categoriesRoutes);
router.use('/products', productsRoutes);
router.use('/customers', customersRoutes);
router.use('/orders', ordersRoutes);

module.exports = router;
