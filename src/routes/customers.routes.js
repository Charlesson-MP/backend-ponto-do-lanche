const { Router } = require('express');
const router = Router();
const customersController = require('../controllers/customers.controller');

router.get('/', customersController.listCustomers);
router.get('/:id', customersController.getCustomerById);
router.post('/', customersController.createCustomer);
router.put('/:id', customersController.updateCustomer);
router.delete('/:id', customersController.deleteCustomer);

module.exports = router;
