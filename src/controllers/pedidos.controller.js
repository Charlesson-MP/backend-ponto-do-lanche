const pedidosService = require('../services/pedidos.service');
const clientesService = require('../services/clientes.service');
const produtosService = require('../services/produtos.service');

/**
 * Valida dados do pedido e retorna o total calculado.
 * @returns {Promise<{ error: string|null, total: number, produtosValidados: Array }>}
 */
const validateAndCalculateOrder = async ({ cliente_id, produtos }) => {
  // 1. Cliente
  if (!cliente_id || isNaN(cliente_id)) {
    return { error: 'O campo "cliente_id" é obrigatório e deve ser um número.', total: 0 };
  }
  const cliente = await clientesService.findById(Number(cliente_id));
  if (!cliente) {
    return { error: `Cliente com ID ${cliente_id} não encontrado.`, total: 0 };
  }

  // 2. Produtos (Array)
  if (!produtos || !Array.isArray(produtos) || produtos.length === 0) {
    return { error: 'O campo "produtos" deve ser uma lista não vazia.', total: 0 };
  }

  let totalCalculado = 0;
  const produtosValidados = [];

  for (const item of produtos) {
    if (!item.id || !item.quantidade || Number(item.quantidade) <= 0) {
      return { error: 'Cada item deve ter "id" e "quantidade" maior que zero.', total: 0 };
    }

    // Buscar produto para pegar preço real
    const produtoDb = await produtosService.findById(Number(item.id));
    if (!produtoDb) {
      return { error: `Produto com ID ${item.id} não encontrado.`, total: 0 };
    }

    const preco = Number(produtoDb.preco);
    const qtd = Number(item.quantidade);
    const subtotal = preco * qtd;

    totalCalculado += subtotal;
    produtosValidados.push({
      id: produtoDb.id,
      nome: produtoDb.nome, // Opcional: guardar nome histórico?
      preco_unitario: preco,
      quantidade: qtd,
      subtotal: subtotal
    });
  }

  return { error: null, total: totalCalculado, produtosValidados };
};

const listar = async (req, res, next) => {
  try {
    const pedidos = await pedidosService.listAll();
    return res.json({
      success: true,
      message: 'Pedidos listados com sucesso',
      data: pedidos,
    });
  } catch (err) {
    next(err);
  }
};

const buscarPorId = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const pedido = await pedidosService.findById(Number(id));
    if (!pedido) return res.status(404).json({ success: false, message: 'Pedido não encontrado.' });

    return res.json({ success: true, data: pedido });
  } catch (err) {
    next(err);
  }
};

const criar = async (req, res, next) => {
  try {
    const { cliente_id, produtos } = req.body;

    // Validação e Cálculo
    const { error, total, produtosValidados } = await validateAndCalculateOrder({ cliente_id, produtos });

    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    const novoPedido = await pedidosService.create({
      cliente_id,
      produtos: produtosValidados, // Salva com detalhes (preço, nome)
      total,
      status: 'Pendente'
    });

    return res.status(201).json({
      success: true,
      message: 'Pedido criado com sucesso',
      data: novoPedido
    });
  } catch (err) {
    next(err);
  }
};

const atualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, produtos } = req.body; // Apenas status ou produtos podem ser atualizados?

    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const pedidoExistente = await pedidosService.findById(Number(id));
    if (!pedidoExistente) return res.status(404).json({ success: false, message: 'Pedido não encontrado.' });

    let updateData = { status: status || pedidoExistente.status };

    // Se atualizar produtos, recalcula total
    if (produtos) {
      const { error, total, produtosValidados } = await validateAndCalculateOrder({
        cliente_id: pedidoExistente.cliente_id, // Mantém cliente
        produtos
      });
      if (error) return res.status(400).json({ success: false, message: error });

      updateData.produtos = produtosValidados;
      updateData.total = total;
    }

    const pedidoAtualizado = await pedidosService.update(Number(id), updateData);

    return res.json({
      success: true,
      message: 'Pedido atualizado com sucesso',
      data: pedidoAtualizado
    });
  } catch (err) {
    next(err);
  }
};

const remover = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID inválido.' });

    const pedido = await pedidosService.remove(Number(id));
    if (!pedido) return res.status(404).json({ success: false, message: 'Pedido não encontrado.' });

    return res.json({ success: true, message: 'Pedido removido com sucesso' });
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
