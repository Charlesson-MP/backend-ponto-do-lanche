const ordersService = require('../services/orders.service');
const storeSettingsService = require('../services/store-settings.service');

const listOrders = async (req, res, next) => {
  try {
    const orders = await ordersService.listOrders();
    return res.json({ success: true, data: orders });
  } catch (err) {
    next(err);
  }
};

const createOrder = async (req, res, next) => {
  const { customer_name, customer_phone, delivery_type, delivery_address, payment_method, change_for, items } = req.body;

  if (!customer_name || !customer_phone || !items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, message: 'Faltam dados obrigatórios no pedido.' });
  }

  try {
    // Pegar limites usando o service de configurações
    const settings = await storeSettingsService.getStoreSettings();
    if (!settings) throw new Error('Store settings not found');

    const { max_addons, delivery_fee } = settings;

    const orderData = {
      customer_name,
      customer_phone,
      delivery_type,
      delivery_address,
      payment_method,
      change_for,
      items,
      max_addons,
      delivery_fee
    };

    const orderId = await ordersService.createOrder(orderData);

    return res.status(201).json({ success: true, message: 'Pedido criado com sucesso.', data: { id: orderId } });

  } catch (err) {
    // Pegar checks específicos que caem no PG
    if (err.code === '23514') { // check_violation
      return res.status(400).json({ success: false, message: 'Valores ou informações não seguiram regras do banco! (Troco / Endereço / Precificação)' });
    }
    const status = err.status || 500;
    return res.status(status).json({ success: false, message: err.message || 'Erro ao processar pedido.' });
  }
};

module.exports = {
  listOrders,
  createOrder
};
