const { query } = require('../db');

const listCategories = async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM categories ORDER BY display_order ASC', []);
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

module.exports = { listCategories };
