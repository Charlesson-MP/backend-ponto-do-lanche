const { Router } = require('express');

const router = Router();

// Health-check / rota raiz da API
router.get('/', (_req, res) => {
  res.json({
    success: true,
    message: 'API Ponto do Lanche — funcionando! 🍔',
    timestamp: new Date().toISOString(),
  });
});

// Rota de teste
router.get('/test', (_req, res) => {
  res.json({
    success: true,
    message: 'Backend funcionando!',
  });
});

// -----------------------------------------------
// Registrar rotas dos módulos
// -----------------------------------------------
const produtosRoutes = require('./produtos.routes');
router.use('/produtos', produtosRoutes);

module.exports = router;
