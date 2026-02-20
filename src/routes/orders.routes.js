const { Router } = require('express');
const router = Router();
const ordersController = require('../controllers/orders.controller');

router.get('/', ordersController.listOrders);
router.post('/', ordersController.createOrder);

module.exports = router;
