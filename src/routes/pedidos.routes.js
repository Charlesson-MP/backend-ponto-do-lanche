const express = require('express');
const router = express.Router();
const pedidosController = require('../controllers/pedidos.controller');

router.get('/', pedidosController.listar);
router.get('/:id', pedidosController.buscarPorId);
router.post('/', pedidosController.criar);
router.put('/:id', pedidosController.atualizar);
router.delete('/:id', pedidosController.remover);

module.exports = router;
