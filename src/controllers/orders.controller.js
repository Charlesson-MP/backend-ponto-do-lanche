const { getClient, query } = require('../db');

const listOrders = async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM orders ORDER BY created_at DESC', []);
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

const createOrder = async (req, res, next) => {
  const { customer_name, customer_phone, delivery_type, delivery_address, payment_method, change_for, items } = req.body;

  if (!customer_name || !customer_phone || !items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, message: 'Faltam dados obrigatórios no pedido.' });
  }

  const client = await getClient();
  try {
    await client.query('BEGIN');

    // Pegar limites
    const settingsRes = await client.query('SELECT max_addons, delivery_fee FROM store_settings WHERE id = 1');
    if (settingsRes.rows.length === 0) throw new Error('Store settings not found');
    const { max_addons, delivery_fee } = settingsRes.rows[0];

    // Calcular ticket e validar os items
    let subtotal = 0;

    for (const item of items) {
      if (!item.product_id || !item.quantity || item.quantity <= 0) {
        throw { status: 400, message: 'Item inválido.' };
      }

      // Validação de backend (conforme scripts): regra max_addons
      if (item.addons && Array.isArray(item.addons)) {
        if (item.addons.length > max_addons) {
          throw { status: 400, message: `O produto passou do limite de ${max_addons} adicionais.` };
        }
      }

      // Pode ser checado no banco pra valer se o produto existe. 
      // Mas para simplificar conforme o schema exige, usamos values passados
      const basePrice = Number(item.base_price || 0);
      const addonsTotal = Number(item.addons_total || 0);
      const finalPrice = Number(item.final_price || 0);

      subtotal += finalPrice * item.quantity;
    }

    const orderDeliveryFee = delivery_type === 'delivery' ? Number(delivery_fee) : 0;
    const total = subtotal + orderDeliveryFee;

    // A constraint do banco `ck_orders_change_for` vai barrar se o change_for < total 
    // ou se o tipo de pagamento não for 'cash'
    // A constraint `ck_orders_delivery_address` vai barrar logradouro vazio de delivery (TRIM)

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
    return res.status(201).json({ success: true, message: 'Pedido criado com sucesso.', data: { id: orderId } });

  } catch (err) {
    await client.query('ROLLBACK');
    // Pegar checks específicos que caem no PG
    if (err.code === '23514') { // check_violation
      return res.status(400).json({ success: false, message: 'Valores ou informações não seguiram regras do banco! (Troco / Endereço / Precificação)' });
    }
    const status = err.status || 500;
    return res.status(status).json({ success: false, message: err.message || 'Erro ao processar pedido.' });
  } finally {
    client.release();
  }
};

module.exports = {
  listOrders,
  createOrder
};
