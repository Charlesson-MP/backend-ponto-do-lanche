const { query } = require('../db');

const listCategories = async () => {
  const result = await query('SELECT * FROM categories ORDER BY display_order ASC', []);
  return result.rows;
};

module.exports = {
  listCategories,
};
