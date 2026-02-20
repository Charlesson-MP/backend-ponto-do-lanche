const http = require('http');
const fs = require('fs');
const baseURL = 'http://localhost:3000';
const resultsFile = 'test_results.txt';
// Clear previous results
fs.writeFileSync(resultsFile, '');
const log = (msg) => {
  console.log(msg);
  fs.appendFileSync(resultsFile, msg + '\n');
};
const makeRequest = (method, path, body = null) => {
  return new Promise((resolve, reject) => {
    const options = {
      method,
      hostname: 'localhost',
      port: 3000,
      path: '/api' + path,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          data: data ? JSON.parse(data) : null
        });
      });
    });
    req.on('error', (error) => {
      reject(error);
    });
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
};
async function runTests() {
  log('\n======================================');
  log('🤖 Backend Validation Script Inicializado');
  log('======================================\n');
  try {
    // 1️⃣ Verificar store_settings
    log('1️⃣ Testando GET /store-settings...');
    const settings = await makeRequest('GET', '/store-settings');
    log('Status: ' + settings.statusCode);
    if (settings.statusCode === 200 && settings.data.data && settings.data.data.max_addons === 3) {
      log('✅ store_settings retornou os dados singleton corretamente.');
    } else {
      log('❌ Falha: ' + JSON.stringify(settings.data));
    }
    log('--------------------------------------');
    // 2️⃣ Listar categorias e produtos
    log('2️⃣ Testando GET /categories e GET /products...');
    const categories = await makeRequest('GET', '/categories');
    const products = await makeRequest('GET', '/products');
    let categoriasOk = false, produtosOk = false;
    if (categories.statusCode === 200 && Array.isArray(categories.data) && categories.data.length > 0) {
      log('✅ GET /categories OK. Count: ' + categories.data.length);
      categoriasOk = true;
    } else log('❌ GET /categories Falhou: ' + JSON.stringify(categories.data));
    if (products.statusCode === 200 && Array.isArray(products.data) && products.data.length > 0) {
      log('✅ GET /products OK. Count: ' + products.data.length);
      produtosOk = true;
    } else log('❌ GET /products Falhou: ' + JSON.stringify(products.data));
    log('--------------------------------------');
    // 3️⃣ Criar pedido válido
    log('3️⃣ Testando POST /orders com dados corretos...');
    const orderData = {
      customer_name: "João Silva",
      customer_phone: "5511999998888",
      delivery_type: "delivery",
      delivery_address: "Rua das Flores, 123",
      payment_method: "cash",
      change_for: 30, // modificado pra >= finalPrice
      items: [
        {
          product_id: 1,
          quantity: 1,
          addons: [{ "id": 1, "price": 4.00, "name": "Bacon crocante", "product_id": 1 }],
          base_price: 15.99,
          addons_total: 4.00,
          final_price: 19.99
        }
      ]
    };
    const validOrder = await makeRequest('POST', '/orders', orderData);
    log('Status POST: ' + validOrder.statusCode);
    if (validOrder.statusCode >= 200 && validOrder.statusCode < 300) {
      log('✅ Pedido criado com sucesso (troco >= total).');
    } else {
      log('❌ Falha ao criar pedido: ' + JSON.stringify(validOrder.data));
    }
    log('--------------------------------------');
    // 4️⃣ Teste troco inválido
    log('4️⃣ Testando POST /orders com troco insuficiente...');
    const invalidChangeOrder = { ...orderData, change_for: 10 };
    const invalidOrder = await makeRequest('POST', '/orders', invalidChangeOrder);
    log('Status POST: ' + invalidOrder.statusCode);
    if (invalidOrder.statusCode >= 400 || invalidOrder.statusCode === 500) {
      log('✅ Pedido barrado pela constraint/backend corretamente.');
    } else {
      log('❌ Falha! Pedido com troco inválido foi aceito!');
    }
    log('--------------------------------------');
    // 5️⃣ Teste limite de addons 
    log('5️⃣ Testando limite max_addons...');
    const tooManyAddonsData = {
      ...orderData,
      items: [
        {
          product_id: 1,
          quantity: 1,
          addons: [
            { "id": 1, "price": 4.00 }, { "id": 2, "price": 3.00 },
            { "id": 3, "price": 2.50 }, { "id": 4, "price": 5.00 }
          ],
          base_price: 15.99,
          addons_total: 14.50,
          final_price: 30.49
        }
      ]
    };
    const addonsOrderReq = await makeRequest('POST', '/orders', tooManyAddonsData);
    log('Status POST: ' + addonsOrderReq.statusCode);
    if (addonsOrderReq.statusCode >= 400 || addonsOrderReq.statusCode === 500) {
      log('✅ Pedido barrado devido a limite de addons (ou pelo banco).');
    } else {
      log('❌ Falha! Pedido com excesso de adicionais aceito!');
    }
    log('--------------------------------------');
    // 6️⃣ Testar atualização de produto
    log('6️⃣ Testando PUT /products/1...');
    const putProd = await makeRequest('PUT', '/products/1', { price: 16.50 });
    log('Status PUT: ' + putProd.statusCode);
    if (putProd.statusCode >= 200 && putProd.statusCode < 300) {
      log('✅ Atualização ok. trigger executada com sucesso.');
    } else {
      log('❌ Erro no PUT /products/1: ' + JSON.stringify(putProd.data));
    }
    log('--------------------------------------');
    // 7️⃣ Testar exclusão de produto com relacionamento (ON DELETE RESTRICT)
    log('7️⃣ Testando DELETE /products/1 (Produto em Ordem)...');
    const delProd = await makeRequest('DELETE', '/products/1');
    log('Status DELETE: ' + delProd.statusCode);
    if (delProd.statusCode >= 400 || delProd.statusCode === 500) {
      log('✅ Falha correta ao deletar - bloqueado pelo PostgreSQL (RESTRICT).');
    } else {
      log('❌ Erro crítico: Produto deletado com sucesso!');
    }
    log('--------------------------------------');
    // 8️⃣ Teste endereços inválidos
    log('8️⃣ Testando POST /orders com endereço vazio de espaços...');
    const invalidAddressOrder = { ...orderData, delivery_address: "   " };
    const invalidAddrReq = await makeRequest('POST', '/orders', invalidAddressOrder);
    log('Status POST: ' + invalidAddrReq.statusCode);
    if (invalidAddrReq.statusCode >= 400 || invalidAddrReq.statusCode === 500) {
      log('✅ Rejeitado pelo banco devida a constraint TRIM() <> "".');
    } else {
      log('❌ Erro crítico: Endereço vazio foi aceito!');
    }
    log('--------------------------------------');
    // 9️⃣ Listar orders
    log('9️⃣ Testando GET /orders...');
    const listOrders = await makeRequest('GET', '/orders');
    log('Status GET: ' + listOrders.statusCode);
    if (listOrders.statusCode === 200 && listOrders.data.data && Array.isArray(listOrders.data.data) && listOrders.data.data.length > 0) {
      log('✅ Lista de pedidos retornada com sucesso.');
    } else {
      log('❌ Lista de pedidos falhou: ' + JSON.stringify(listOrders.data));
    }
    log('\n======================================');
    log('🏁 Pipeline de validações concluído!');
    log('======================================');
  } catch (err) {
    if (err.code === 'ECONNREFUSED') {
      log('\n❌ O backend não parece estar rodando em http://localhost:3000');
    } else {
      log('\n❌ Erro na pipeline de testes: ' + err.message);
    }
  }
}
runTests();