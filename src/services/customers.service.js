const { query } = require('../db');

const listCustomers = async () => {
  const result = await query('SELECT * FROM customers ORDER BY created_at DESC', []);
  return result.rows;
};

const getCustomerById = async (id) => {
  const result = await query('SELECT * FROM customers WHERE id = $1', [id]);
  return result.rows.length > 0 ? result.rows[0] : null;
};

const getCustomerByPhone = async (phone) => {
  const result = await query('SELECT id FROM customers WHERE phone = $1', [phone]);
  return result.rows.length > 0 ? result.rows[0] : null;
};

const createCustomer = async (customerData) => {
  const { name, phone, street, number, neighborhood, complement } = customerData;
  const result = await query(
    `INSERT INTO customers (name, phone, street, number, neighborhood, complement)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [name, phone, street, number, neighborhood, complement]
  );
  return result.rows[0];
};

const updateCustomer = async (id, customerData) => {
  const { name, phone, street, number, neighborhood, complement } = customerData;
  const result = await query(
    `UPDATE customers 
     SET name = $1, phone = $2, street = $3, number = $4, neighborhood = $5, complement = $6
     WHERE id = $7 RETURNING *`,
    [name, phone, street, number, neighborhood, complement, id]
  );
  return result.rows.length > 0 ? result.rows[0] : null;
};

const deleteCustomer = async (id) => {
  const result = await query('DELETE FROM customers WHERE id = $1 RETURNING id', [id]);
  return result.rows.length > 0 ? result.rows[0] : null;
};

module.exports = {
  listCustomers,
  getCustomerById,
  getCustomerByPhone,
  createCustomer,
  updateCustomer,
  deleteCustomer
};
