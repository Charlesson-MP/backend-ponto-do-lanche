const { query } = require('../db');

const listProducts = async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM products ORDER BY display_order ASC', []);
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

const updateProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { price } = req.body;

    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });
    if (price === undefined) return res.status(400).json({ success: false, message: 'Price is required' });

    const result = await query(
      'UPDATE products SET price = $1 WHERE id = $2 RETURNING *',
      [price, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produto não encontrado.' });
    }

    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

const deleteProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const result = await query('DELETE FROM products WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produto não encontrado.' });
    }

    return res.json({ success: true, message: 'Produto removido com sucesso' });
  } catch (err) {
    if (err.code === '23503') { // foreign_key_violation
      return res.status(400).json({ success: false, message: 'Não é possível remover produto vinculado a um pedido.' });
    }
    next(err);
  }
};

module.exports = {
  listProducts,
  updateProduct,
  deleteProduct
};
