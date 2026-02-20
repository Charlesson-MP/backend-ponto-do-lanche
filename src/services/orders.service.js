const { getClient, query } = require('../db');

const listOrders = async () => {
  const result = await query('SELECT * FROM orders ORDER BY created_at DESC', []);
  return result.rows;
};

const createOrder = async (orderData) => {
  const { customer_name, customer_phone, delivery_type, delivery_address, payment_method, change_for, items, max_addons, delivery_fee } = orderData;

  const client = await getClient();
  try {
    await client.query('BEGIN');

    let subtotal = 0;

    for (const item of items) {
      if (!item.product_id || !item.quantity || item.quantity <= 0) {
        throw { status: 400, message: 'Item inválido.' };
      }
      if (item.addons && Array.isArray(item.addons)) {
        if (item.addons.length > max_addons) {
          throw { status: 400, message: `O produto passou do limite de ${max_addons} adicionais.` };
        }
      }

      const finalPrice = Number(item.final_price || 0);
      subtotal += finalPrice * item.quantity;
    }

    const orderDeliveryFee = delivery_type === 'delivery' ? Number(delivery_fee) : 0;
    const total = subtotal + orderDeliveryFee;

    const orderResult = await client.query(
      `INSERT INTO orders 
        (customer_name, customer_phone, delivery_type, delivery_address, payment_method, change_for, subtotal, delivery_fee, total, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
       RETURNING id`,
      [customer_name, customer_phone, delivery_type, delivery_address || null, payment_method, change_for || null, subtotal, orderDeliveryFee, total]
    );

    const orderId = orderResult.rows[0].id;

    for (const item of items) {
      await client.query(
        `INSERT INTO order_items 
          (order_id, product_id, product_name, quantity, base_price, addons_total, final_price, selected_addons)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          orderId,
          item.product_id,
          item.product_name || 'Produto',
          item.quantity,
          item.base_price,
          item.addons_total || 0,
          item.final_price,
          item.addons ? JSON.stringify(item.addons) : '[]'
        ]
      );
    }

    await client.query('COMMIT');
    return orderId;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  listOrders,
  createOrder
};
