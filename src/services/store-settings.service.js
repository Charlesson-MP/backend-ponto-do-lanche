const { query } = require('../db');

const getStoreSettings = async () => {
  const result = await query('SELECT * FROM store_settings WHERE id = 1 LIMIT 1', []);
  return result.rows.length > 0 ? result.rows[0] : null;
};

module.exports = {
  getStoreSettings,
};
