const produtosService = require('../services/produtos.service');

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
 *
 * Body esperado:
 *   { "nome": "X-Burguer", "descricao": "Hambúrguer com queijo", "preco": 18.90 }
 */
const criar = async (req, res, next) => {
  try {
    const { nome, descricao, preco } = req.body;

    // Validações
    if (!nome || nome.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'O campo "nome" é obrigatório.',
      });
    }

    if (preco === undefined || preco === null || isNaN(preco) || Number(preco) < 0) {
      return res.status(400).json({
        success: false,
        message: 'O campo "preco" é obrigatório e deve ser um número positivo.',
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
 *
 * Body esperado:
 *   { "nome": "X-Salada", "descricao": "Hambúrguer com salada", "preco": 20.50 }
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

    if (!nome || nome.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'O campo "nome" é obrigatório.',
      });
    }

    if (preco === undefined || preco === null || isNaN(preco) || Number(preco) < 0) {
      return res.status(400).json({
        success: false,
        message: 'O campo "preco" é obrigatório e deve ser um número positivo.',
      });
    }

    const produto = await produtosService.update(Number(id), {
      nome: nome.trim(),
      descricao: descricao ? descricao.trim() : '',
      preco: Number(preco),
    });

    if (!produto) {
      return res.status(404).json({
        success: false,
        message: `Produto com ID ${id} não encontrado`,
      });
    }

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
