const { Router } = require('express');
const router = Router();
const storeSettingsController = require('../controllers/store-settings.controller');

router.get('/', storeSettingsController.getSettings);

module.exports = router;
