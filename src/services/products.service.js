const { query, getClient } = require('../db');

const listProducts = async () => {
  const productsResult = await query('SELECT * FROM products ORDER BY display_order ASC', []);
  const products = productsResult.rows;

  // Para cada produto, buscar os sub-itens
  // Em uma escala maior, usaríamos um único JOIN com JSON_AGG para performance
  for (let product of products) {
    const [ingredients, addons, flavors, sizes] = await Promise.all([
      query('SELECT * FROM product_ingredients WHERE product_id = $1 ORDER BY display_order ASC', [product.id]),
      query('SELECT * FROM product_addons WHERE product_id = $1 ORDER BY display_order ASC', [product.id]),
      query('SELECT * FROM product_flavors WHERE product_id = $1 ORDER BY display_order ASC', [product.id]),
      query('SELECT * FROM product_sizes WHERE product_id = $1 ORDER BY display_order ASC', [product.id])
    ]);

    product.ingredients = ingredients.rows;
    product.addons = addons.rows;
    product.flavors = flavors.rows;
    product.sizes = sizes.rows;
  }

  return products;
};

const updateProductDeep = async (id, productData) => {
  const {
    category_id, name, description, price, image_url, is_active, is_featured, display_order,
    ingredients, addons, flavors, sizes
  } = productData;

  const client = await getClient();
  try {
    await client.query('BEGIN');

    // 1. Atualizar campos básicos
    const updateCoreResult = await client.query(
      `UPDATE products 
       SET category_id = COALESCE($1, category_id),
           name = COALESCE($2, name),
           description = COALESCE($3, description),
           price = COALESCE($4, price),
           image_url = COALESCE($5, image_url),
           is_active = COALESCE($6, is_active),
           is_featured = COALESCE($7, is_featured),
           display_order = COALESCE($8, display_order),
           updated_at = NOW()
       WHERE id = $9 RETURNING *`,
      [
        category_id !== undefined ? category_id : null,
        name !== undefined ? name : null,
        description !== undefined ? description : null,
        price !== undefined ? price : null,
        image_url !== undefined ? image_url : null,
        is_active !== undefined ? is_active : null,
        is_featured !== undefined ? is_featured : null,
        display_order !== undefined ? display_order : null,
        id
      ]
    );

    if (updateCoreResult.rows.length === 0) {
      throw { status: 404, message: 'Produto não encontrado' };
    }

    const updatedProduct = updateCoreResult.rows[0];

    // 2. Sincronizar Sub-tabelas (Abordagem Delete & Re-insert para simplicidade do Admin)

    // Ingredients
    if (ingredients && Array.isArray(ingredients)) {
      await client.query('DELETE FROM product_ingredients WHERE product_id = $1', [id]);
      for (const item of ingredients) {
        await client.query(
          'INSERT INTO product_ingredients (product_id, name, is_removable, display_order) VALUES ($1, $2, $3, $4)',
          [id, item.name, item.is_removable !== false, item.display_order || 0]
        );
      }
    }

    // Addons
    if (addons && Array.isArray(addons)) {
      await client.query('DELETE FROM product_addons WHERE product_id = $1', [id]);
      for (const item of addons) {
        await client.query(
          'INSERT INTO product_addons (product_id, name, price, is_active, display_order) VALUES ($1, $2, $3, $4, $5)',
          [id, item.name, item.price || 0, item.is_active !== false, item.display_order || 0]
        );
      }
    }

    // Flavors
    if (flavors && Array.isArray(flavors)) {
      await client.query('DELETE FROM product_flavors WHERE product_id = $1', [id]);
      for (const item of flavors) {
        await client.query(
          'INSERT INTO product_flavors (product_id, name, is_available, display_order) VALUES ($1, $2, $3, $4)',
          [id, item.name, item.is_available !== false, item.display_order || 0]
        );
      }
    }

    // Sizes
    if (sizes && Array.isArray(sizes)) {
      await client.query('DELETE FROM product_sizes WHERE product_id = $1', [id]);
      for (const item of sizes) {
        await client.query(
          'INSERT INTO product_sizes (product_id, name, ml, price, is_available, display_order) VALUES ($1, $2, $3, $4, $5, $6)',
          [id, item.name, item.ml || null, item.price || 0, item.is_available !== false, item.display_order || 0]
        );
      }
    }

    await client.query('COMMIT');

    // Retornar o produto completo atualizado
    const finalProductResult = await client.query('SELECT * FROM products WHERE id = $1', [id]);
    const finalProduct = finalProductResult.rows[0];

    const [finIng, finAdd, finFlav, finSize] = await Promise.all([
      client.query('SELECT * FROM product_ingredients WHERE product_id = $1', [id]),
      client.query('SELECT * FROM product_addons WHERE product_id = $1', [id]),
      client.query('SELECT * FROM product_flavors WHERE product_id = $1', [id]),
      client.query('SELECT * FROM product_sizes WHERE product_id = $1', [id])
    ]);

    finalProduct.ingredients = finIng.rows;
    finalProduct.addons = finAdd.rows;
    finalProduct.flavors = finFlav.rows;
    finalProduct.sizes = finSize.rows;

    return finalProduct;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const deleteProduct = async (id) => {
  const result = await query('DELETE FROM products WHERE id = $1 RETURNING *', [id]);
  return result.rows.length > 0 ? result.rows[0] : null;
};

module.exports = {
  listProducts,
  updateProductDeep,
  deleteProduct
};
