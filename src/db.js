const { Pool } = require('pg');

// Pool de conexão com o PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Log de conexão
pool.on('connect', () => {
  console.log('📦 Conectado ao banco de dados PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Erro inesperado no pool do banco de dados:', err);
  process.exit(1);
});

/**
 * Executa uma query no banco de dados.
 * @param {string} text  - A query SQL
 * @param {Array}  params - Parâmetros da query
 * @returns {Promise<import('pg').QueryResult>}
 */
const query = (text, params) => pool.query(text, params);

/**
 * Obtém um client do pool para transações.
 * @returns {Promise<import('pg').PoolClient>}
 */
const getClient = () => pool.connect();

module.exports = {
  pool,
  query,
  getClient,
};
