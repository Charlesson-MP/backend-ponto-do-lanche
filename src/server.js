require('dotenv').config();

const app = require('./app');
const db = require('./config/database');

const PORT = process.env.PORT || 3000;

// Testar conexão com o banco e iniciar o servidor
(async () => {
  try {
    await db.query('SELECT NOW()');
    console.log('✅ Conexão com o banco de dados estabelecida com sucesso');
  } catch (err) {
    console.warn('⚠️  Não foi possível conectar ao banco de dados:', err.message);
    console.warn('⚠️  O servidor será iniciado sem conexão ativa com o banco');
  }

  app.listen(PORT, () => {
    console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
    console.log(`📡 Ambiente: ${process.env.NODE_ENV || 'development'}`);
  });
})();
