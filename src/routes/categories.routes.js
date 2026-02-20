const { Router } = require('express');
const router = Router();
const categoriesController = require('../controllers/categories.controller');

router.get('/', categoriesController.listCategories);

module.exports = router;
