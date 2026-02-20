const produtosService = require('../services/produtos.service');

/**
 * Helper para validar dados de entrada.
 * Retorna string com erro ou null se válido.
 */
const validateProduct = async ({ nome, descricao, preco }, id = null) => {
  // 1. Validar Nome
  if (!nome || typeof nome !== 'string' || nome.trim().length < 3 || nome.trim().length > 100) {
    return 'O campo "nome" é obrigatório e deve ter entre 3 e 100 caracteres.';
  }

  // 2. Validar Preço
  if (preco === undefined || preco === null || isNaN(preco) || Number(preco) <= 0) {
    return 'O campo "preco" é obrigatório e deve ser um número maior que zero.';
  }

  // 3. Validar Descrição
  if (descricao && descricao.length > 255) {
    return 'O campo "descricao" deve ter no máximo 255 caracteres.';
  }

  // 4. Validar Duplicidade de Nome
  const existingProduct = await produtosService.findByName(nome.trim());
  if (existingProduct) {
    // Se for atualização, ignora se o produto encontrado for o mesmo que estamos editando
    if (id && existingProduct.id === Number(id)) {
      return null;
    }
    return 'Já existe um produto com este nome.';
  }

  return null;
};

/**
 * GET /api/produtos
 * Retorna todos os produtos.
 */
const listar = async (req, res, next) => {
  try {
    const produtos = await produtosService.listAll();
    return res.json({
      success: true,
      message: 'Produtos listados com sucesso',
      data: produtos,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/produtos/:id
 * Retorna um produto pelo ID.
 */
const buscarPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({
        success: false,
        message: 'ID inválido. Deve ser um número.',
      });
    }

    const produto = await produtosService.findById(Number(id));

    if (!produto) {
      return res.status(404).json({
        success: false,
        message: `Produto com ID ${id} não encontrado`,
      });
    }

    return res.json({
      success: true,
      message: 'Produto encontrado',
      data: produto,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/produtos
 * Cria um novo produto.
 */
const criar = async (req, res, next) => {
  try {
    const { nome, descricao, preco } = req.body;

    // Validação
    const error = await validateProduct({ nome, descricao, preco });
    if (error) {
      return res.status(400).json({
        success: false,
        message: error,
      });
    }

    const produto = await produtosService.create({
      nome: nome.trim(),
      descricao: descricao ? descricao.trim() : '',
      preco: Number(preco),
    });

    return res.status(201).json({
      success: true,
      message: 'Produto criado com sucesso',
      data: produto,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/produtos/:id
 * Atualiza um produto existente.
 */
const atualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nome, descricao, preco } = req.body;

    if (isNaN(id)) {
      return res.status(400).json({
        success: false,
        message: 'ID inválido. Deve ser um número.',
      });
    }

    // Verificar se o produto existe antes de validar (para evitar erro de validação em produto inexistente)
    // Embora o requisito peça para validar 'se o produto existe', a validação de duplicidade
    // precisa saber se é update.
    // Vamos checar existência primeiro.
    const existing = await produtosService.findById(Number(id));
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: `Produto com ID ${id} não encontrado`,
      });
    }

    // Validação
    const error = await validateProduct({ nome, descricao, preco }, id);
    if (error) {
      return res.status(400).json({
        success: false,
        message: error,
      });
    }

    const produto = await produtosService.update(Number(id), {
      nome: nome.trim(),
      descricao: descricao ? descricao.trim() : '',
      preco: Number(preco),
    });

    return res.json({
      success: true,
      message: 'Produto atualizado com sucesso',
      data: produto,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/produtos/:id
 * Remove um produto pelo ID.
 */
const remover = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({
        success: false,
        message: 'ID inválido. Deve ser um número.',
      });
    }

    const produto = await produtosService.remove(Number(id));

    if (!produto) {
      return res.status(404).json({
        success: false,
        message: `Produto com ID ${id} não encontrado`,
      });
    }

    return res.json({
      success: true,
      message: `Produto "${produto.nome}" removido com sucesso`,
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
