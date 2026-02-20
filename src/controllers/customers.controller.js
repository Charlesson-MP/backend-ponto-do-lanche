const customersService = require('../services/customers.service');

/**
 * Valida dados de entrada para Clientes e verifica duplicidade.
 * O phone agora é obrigatório e único.
 */
const validateCustomer = async ({ name, phone, street, number, neighborhood, complement }, id = null) => {
  if (!name || typeof name !== 'string' || name.trim().length < 3 || name.trim().length > 150) {
    return 'O campo "name" é obrigatório e deve ter entre 3 e 150 caracteres.';
  }

  if (!phone || typeof phone !== 'string' || phone.trim().length < 8 || phone.trim().length > 20) {
    return 'O campo "phone" é obrigatório e deve ter entre 8 e 20 caracteres.';
  }

  if (street && street.length > 255) return 'O campo "street" deve ter no máximo 255 caracteres.';
  if (number && number.length > 20) return 'O campo "number" deve ter no máximo 20 caracteres.';
  if (neighborhood && neighborhood.length > 100) return 'O campo "neighborhood" deve ter no máximo 100 caracteres.';
  if (complement && complement.length > 255) return 'O campo "complement" deve ter no máximo 255 caracteres.';

  // Verificar se o telefone já existe
  const existing = await customersService.getCustomerByPhone(phone.trim());
  if (existing) {
    if (id && existing.id === Number(id)) {
      return null; // OK: is the same customer being updated
    }
    return 'Já existe um cliente cadastrado com este telefone.';
  }

  return null;
};

const listCustomers = async (req, res, next) => {
  try {
    const customers = await customersService.listCustomers();
    return res.json({ success: true, data: customers });
  } catch (err) {
    next(err);
  }
};

const getCustomerById = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const customer = await customersService.getCustomerById(id);
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Cliente não encontrado.' });
    }

    return res.json({ success: true, data: customer });
  } catch (err) {
    next(err);
  }
};

const createCustomer = async (req, res, next) => {
  try {
    const { name, phone, street, number, neighborhood, complement } = req.body;

    const error = await validateCustomer({ name, phone, street, number, neighborhood, complement });
    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    const customerData = {
      name: name.trim(),
      phone: phone.trim(),
      street: street?.trim() || null,
      number: number?.trim() || null,
      neighborhood: neighborhood?.trim() || null,
      complement: complement?.trim() || null,
    };

    const newCustomer = await customersService.createCustomer(customerData);

    return res.status(201).json({ success: true, message: 'Cliente criado com sucesso', data: newCustomer });
  } catch (err) {
    // Tratamento genérico para falha de uniqueness q não foi pega
    if (err.code === '23505') {
      return res.status(400).json({ success: false, message: 'Já existe um cliente cadastrado com estes dados (ex: telefone).' });
    }
    next(err);
  }
};

const updateCustomer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, phone, street, number, neighborhood, complement } = req.body;

    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    // Verifica se arquivo existe
    const existCheck = await customersService.getCustomerById(id);
    if (!existCheck) return res.status(404).json({ success: false, message: 'Cliente não encontrado.' });

    const error = await validateCustomer({ name, phone, street, number, neighborhood, complement }, id);
    if (error) return res.status(400).json({ success: false, message: error });

    const customerData = {
      name: name.trim(),
      phone: phone.trim(),
      street: street?.trim() || null,
      number: number?.trim() || null,
      neighborhood: neighborhood?.trim() || null,
      complement: complement?.trim() || null,
    };

    const updatedCustomer = await customersService.updateCustomer(id, customerData);

    return res.json({ success: true, message: 'Cliente atualizado com sucesso', data: updatedCustomer });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ success: false, message: 'Telefone já cadastrado em outro cliente.' });
    }
    next(err);
  }
};

const deleteCustomer = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const deletedCustomer = await customersService.deleteCustomer(id);
    if (!deletedCustomer) {
      return res.status(404).json({ success: false, message: 'Cliente não encontrado.' });
    }

    return res.json({ success: true, message: 'Cliente removido com sucesso' });
  } catch (err) {
    // Restrição se o cliente já realizou pedidos, bloqueia (foreign key constraint violation)
    if (err.code === '23503') {
      return res.status(400).json({ success: false, message: 'Não é possível excluir um cliente que possui histórico de pedidos.' });
    }
    next(err);
  }
};

module.exports = {
  listCustomers,
  getCustomerById,
  createCustomer,
  updateCustomer,
  deleteCustomer
};
