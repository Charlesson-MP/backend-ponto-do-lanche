const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

// Importar rotas
const routes = require('./routes');

const app = express();

// ------------------------------------
// Middlewares
// ------------------------------------
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// ------------------------------------
// Rotas
// ------------------------------------
app.use('/api', routes);

// ------------------------------------
// Rota 404
// ------------------------------------
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: 'Rota não encontrada',
  });
});

// ------------------------------------
// Tratamento global de erros
// ------------------------------------
app.use((err, _req, res, _next) => {
  console.error('🔥 Erro interno:', err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Erro interno do servidor',
  });
});

module.exports = app;
