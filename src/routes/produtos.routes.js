const { Router } = require('express');
const produtosController = require('../controllers/produtos.controller');

const router = Router();

// GET    /api/produtos       → lista todos os produtos
router.get('/', produtosController.listar);

// GET    /api/produtos/:id   → busca produto por ID
router.get('/:id', produtosController.buscarPorId);

// POST   /api/produtos       → cria um novo produto
router.post('/', produtosController.criar);

// PUT    /api/produtos/:id   → atualiza um produto
router.put('/:id', produtosController.atualizar);

// DELETE /api/produtos/:id   → remove um produto
router.delete('/:id', produtosController.remover);

module.exports = router;
