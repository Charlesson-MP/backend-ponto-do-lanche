const db = require('../db');

/**
 * Retorna todos os produtos.
 * @returns {Promise<Array>} Lista de produtos
 */
const listAll = async () => {
  const result = await db.query(
    'SELECT id, nome, descricao, preco, created_at, updated_at FROM produtos ORDER BY id ASC'
  );
  return result.rows;
};

/**
 * Busca um produto pelo ID.
 * @param {number} id - ID do produto
 * @returns {Promise<Object|null>} Produto encontrado ou null
 */
const findById = async (id) => {
  const result = await db.query(
    'SELECT id, nome, descricao, preco, created_at, updated_at FROM produtos WHERE id = $1',
    [id]
  );
  return result.rows[0] || null;
};

/**
 * Busca um produto pelo nome (case insensitive).
 * @param {string} nome - Nome do produto
 * @returns {Promise<Object|null>} Produto encontrado ou null
 */
const findByName = async (nome) => {
  console.log(`Searching for product with name: ${nome}`);
  const result = await db.query(
    'SELECT id, nome FROM produtos WHERE LOWER(nome) = LOWER($1)',
    [nome]
  );
  console.log('Query result:', result.rows);
  return result.rows[0] || null;
};

/**
 * Cria um novo produto.
 *
 * Exemplo de payload:
 *   { "nome": "X-Burguer", "descricao": "Hambúrguer com queijo", "preco": 18.90 }
 *
 * @param {{ nome: string, descricao: string, preco: number }} data
 * @returns {Promise<Object>} Produto criado
 */
const create = async ({ nome, descricao, preco }) => {
  const result = await db.query(
    `INSERT INTO produtos (nome, descricao, preco)
     VALUES ($1, $2, $3)
     RETURNING id, nome, descricao, preco, created_at, updated_at`,
    [nome, descricao, preco]
  );
  return result.rows[0];
};

/**
 * Atualiza um produto existente.
 *
 * Exemplo de payload:
 *   { "nome": "X-Salada", "descricao": "Hambúrguer com salada", "preco": 20.50 }
 *
 * @param {number} id - ID do produto
 * @param {{ nome: string, descricao: string, preco: number }} data
 * @returns {Promise<Object|null>} Produto atualizado ou null se não encontrado
 */
const update = async (id, { nome, descricao, preco }) => {
  const result = await db.query(
    `UPDATE produtos
     SET nome = $1, descricao = $2, preco = $3, updated_at = NOW()
     WHERE id = $4
     RETURNING id, nome, descricao, preco, created_at, updated_at`,
    [nome, descricao, preco, id]
  );
  return result.rows[0] || null;
};

/**
 * Remove um produto pelo ID.
 * @param {number} id - ID do produto
 * @returns {Promise<Object|null>} Produto removido ou null se não encontrado
 */
const remove = async (id) => {
  const result = await db.query(
    'DELETE FROM produtos WHERE id = $1 RETURNING id, nome',
    [id]
  );
  return result.rows[0] || null;
};

module.exports = {
  listAll,
  findById,
  findByName,
  create,
  update,
  remove,
};
