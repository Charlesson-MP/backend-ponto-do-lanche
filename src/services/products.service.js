const { query } = require('../db');

const listProducts = async () => {
  const result = await query('SELECT * FROM products ORDER BY display_order ASC', []);
  return result.rows;
};

const updateProductPrice = async (id, price) => {
  const result = await query(
    'UPDATE products SET price = $1 WHERE id = $2 RETURNING *',
    [price, id]
  );
  return result.rows.length > 0 ? result.rows[0] : null;
};

const deleteProduct = async (id) => {
  const result = await query('DELETE FROM products WHERE id = $1 RETURNING *', [id]);
  return result.rows.length > 0 ? result.rows[0] : null;
};

module.exports = {
  listProducts,
  updateProductPrice,
  deleteProduct
};
