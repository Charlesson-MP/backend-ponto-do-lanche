const db = require('../db');

/**
 * Lista todos os pedidos, ordenados por data de criação (desc).
 */
const listAll = async () => {
  const result = await db.query(
    'SELECT id, cliente_id, produtos, total, status, criado_em FROM pedidos ORDER BY criado_em DESC'
  );
  return result.rows;
};

/**
 * Busca um pedido pelo ID.
 */
const findById = async (id) => {
  const result = await db.query(
    'SELECT id, cliente_id, produtos, total, status, criado_em FROM pedidos WHERE id = $1',
    [id]
  );
  return result.rows[0];
};

/**
 * Cria um novo pedido.
 */
const create = async ({ cliente_id, produtos, total, status }) => {
  const result = await db.query(
    `INSERT INTO pedidos (cliente_id, produtos, total, status)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [cliente_id, JSON.stringify(produtos), total, status || 'Pendente']
  );
  return result.rows[0];
};

/**
 * Atualiza um pedido existente.
 * Permite atualizar status, produtos e total.
 */
const update = async (id, { status, produtos, total }) => {
  // Construção dinâmica da query seria ideal, mas aqui vamos atualizar tudo o que for passado
  // ou manter o que já existe se não passado?
  // Simplificação: o controller deve passar os dados completos ou a query deve ser mais inteligente.
  // Vamos fazer update dos campos passados. Mas SQL estático é mais seguro/simples para este exemplo.
  // Se produtos mudar, total deve mudar. O controller cuidar disso.

  const result = await db.query(
    `UPDATE pedidos
     SET status = COALESCE($1, status),
         produtos = COALESCE($2, produtos),
         total = COALESCE($3, total)
     WHERE id = $4
     RETURNING *`,
    [status, produtos ? JSON.stringify(produtos) : null, total, id]
  );
  return result.rows[0];
};

/**
 * Remove um pedido pelo ID.
 */
const remove = async (id) => {
  const result = await db.query(
    'DELETE FROM pedidos WHERE id = $1 RETURNING id',
    [id]
  );
  return result.rows[0];
};

module.exports = {
  listAll,
  findById,
  create,
  update,
  remove,
};
