const db = require('../db');

/**
 * Lista todos os clientes.
 */
const listAll = async () => {
  const result = await db.query(
    'SELECT id, nome, email, telefone, endereco, criado_em FROM clientes ORDER BY id ASC'
  );
  return result.rows;
};

/**
 * Busca um cliente pelo ID.
 */
const findById = async (id) => {
  const result = await db.query(
    'SELECT id, nome, email, telefone, endereco, criado_em FROM clientes WHERE id = $1',
    [id]
  );
  return result.rows[0];
};

/**
 * Busca um cliente pelo Email.
 */
const findByEmail = async (email) => {
  const result = await db.query(
    'SELECT id, nome, email, telefone, endereco FROM clientes WHERE LOWER(email) = LOWER($1)',
    [email]
  );
  return result.rows[0] || null;
};

/**
 * Cria um novo cliente.
 */
const create = async ({ nome, email, telefone, endereco }) => {
  const result = await db.query(
    `INSERT INTO clientes (nome, email, telefone, endereco)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [nome, email, telefone, endereco]
  );
  return result.rows[0];
};

/**
 * Atualiza um cliente existente.
 */
const update = async (id, { nome, email, telefone, endereco }) => {
  const result = await db.query(
    `UPDATE clientes
     SET nome = $1, email = $2, telefone = $3, endereco = $4
     WHERE id = $5
     RETURNING *`,
    [nome, email, telefone, endereco, id]
  );
  return result.rows[0];
};

/**
 * Remove um cliente pelo ID.
 */
const remove = async (id) => {
  const result = await db.query(
    'DELETE FROM clientes WHERE id = $1 RETURNING id, nome',
    [id]
  );
  return result.rows[0];
};

module.exports = {
  listAll,
  findById,
  findByEmail,
  create,
  update,
  remove,
};
