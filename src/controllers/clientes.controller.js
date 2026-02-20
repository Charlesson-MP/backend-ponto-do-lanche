const clientesService = require('../services/clientes.service');

/**
 * Valida dados de entrada para Clientes.
 * @param {Object} data - { nome, email, telefone, endereco }
 * @param {number|null} id - ID do cliente (para ignorar duplicidade na edição)
 * @returns {Promise<string|null>} String com erro ou null se válido
 */
const validateClient = async ({ nome, email, telefone, endereco }, id = null) => {
  // 1. Nome (Obrigatório, 3-100)
  if (!nome || typeof nome !== 'string' || nome.trim().length < 3 || nome.trim().length > 100) {
    return 'O campo "nome" é obrigatório e deve ter entre 3 e 100 caracteres.';
  }

  // 2. Email (Obrigatório, Válido)
  // Regex simples para teste
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || !emailRegex.test(email)) {
    return 'O campo "email" é obrigatório e deve ser válido.';
  }

  // 3. Telefone (Opcional, max 20)
  if (telefone && telefone.length > 20) {
    return 'O campo "telefone" deve ter no máximo 20 caracteres.';
  }

  // 4. Endereço (Opcional, max 255)
  if (endereco && endereco.length > 255) {
    return 'O campo "endereco" deve ter no máximo 255 caracteres.';
  }

  // 5. Duplicidade de Email
  const existingClient = await clientesService.findByEmail(email.trim());
  if (existingClient) {
    // Se for update, verificar se o ID é diferente
    if (id && existingClient.id === Number(id)) {
      return null;
    }
    return 'Já existe um cliente cadastrado com este e-mail.';
  }

  return null;
};

/**
 * Listar todos os clientes
 */
const listar = async (req, res, next) => {
  try {
    const clientes = await clientesService.listAll();
    return res.json({
      success: true,
      message: 'Clientes listados com sucesso',
      data: clientes,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Buscar cliente por ID
 */
const buscarPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({ success: false, message: 'ID inválido.' });
    }

    const cliente = await clientesService.findById(Number(id));
    if (!cliente) {
      return res.status(404).json({ success: false, message: 'Cliente não encontrado.' });
    }

    return res.json({
      success: true,
      message: 'Cliente encontrado',
      data: cliente,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Criar cliente
 */
const criar = async (req, res, next) => {
  try {
    const { nome, email, telefone, endereco } = req.body;

    // Validação
    const error = await validateClient({ nome, email, telefone, endereco });
    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    const novoCliente = await clientesService.create({
      nome: nome.trim(),
      email: email.trim(),
      telefone: telefone ? telefone.trim() : null,
      endereco: endereco ? endereco.trim() : null,
    });

    return res.status(201).json({
      success: true,
      message: 'Cliente criado com sucesso',
      data: novoCliente,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Atualizar cliente
 */
const atualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nome, email, telefone, endereco } = req.body;

    if (isNaN(id)) {
      return res.status(400).json({ success: false, message: 'ID inválido.' });
    }

    // Verificar existência
    const existing = await clientesService.findById(Number(id));
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Cliente não encontrado.' });
    }

    // Validação
    const error = await validateClient({ nome, email, telefone, endereco }, id);
    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    const clienteAtualizado = await clientesService.update(Number(id), {
      nome: nome.trim(),
      email: email.trim(),
      telefone: telefone ? telefone.trim() : null,
      endereco: endereco ? endereco.trim() : null,
    });

    return res.json({
      success: true,
      message: 'Cliente atualizado com sucesso',
      data: clienteAtualizado,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Remover cliente
 */
const remover = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) {
      return res.status(400).json({ success: false, message: 'ID inválido.' });
    }

    const cliente = await clientesService.remove(Number(id));
    if (!cliente) {
      return res.status(404).json({ success: false, message: 'Cliente não encontrado.' });
    }

    return res.json({
      success: true,
      message: 'Cliente removido com sucesso',
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  listar,
  buscarPorId,
  criar,
  atualizar,
  remover,
};
