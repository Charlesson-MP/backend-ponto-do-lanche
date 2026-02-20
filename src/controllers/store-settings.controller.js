const storeSettingsService = require('../services/store-settings.service');

const getSettings = async (req, res, next) => {
  try {
    const settings = await storeSettingsService.getStoreSettings();
    if (!settings) {
      return res.status(404).json({ success: false, message: 'Configurações de loja não encontradas' });
    }
    return res.json({ success: true, data: settings });
  } catch (err) {
    next(err);
  }
};

module.exports = { getSettings };
