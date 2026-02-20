const { query } = require('../db');

const getSettings = async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM store_settings WHERE id = 1 LIMIT 1', []);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Configurações de loja não encontradas' });
    }
    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

module.exports = { getSettings };
