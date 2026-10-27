const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const env = require('../src/config/env');

test('Scan Kirana Complete API Test Suite', async (t) => {
  await mongoose.connect(env.MONGODB_URI);

  let authToken = '';
  let adminToken = '';
  let testProductId = '';
  let testCustomerId = '';

  const testMobile = `98${Math.floor(10000000 + Math.random() * 90000000)}`;
  const adminMobile = `99${Math.floor(10000000 + Math.random() * 90000000)}`;

  await t.test('GET /health returns 200 ok', async () => {
    const res = await request(app).get('/health');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'ok');
  });

  await t.test('POST /api/v1/auth/register registers shopkeeper with 4-digit PIN', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        mobile: testMobile,
        pin: '1234',
        name: 'Ramesh Patel',
        shopName: 'Shree Ram Kirana Store'
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.ok(res.body.token);
    assert.equal(res.body.user.mobile, testMobile);
    assert.equal(res.body.user.role, 'owner');
    authToken = res.body.token;
  });

  await t.test('POST /api/v1/auth/register registers admin user', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        mobile: adminMobile,
        pin: '9999',
        name: 'Super Admin',
        shopName: 'Admin Central',
        role: 'admin'
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.user.role, 'admin');
    adminToken = res.body.token;
  });

  await t.test('POST /api/v1/auth/login authenticates with 4-digit PIN', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        mobile: testMobile,
        pin: '1234'
      });

    assert.equal(res.status, 200);
    assert.ok(res.body.token);
    assert.equal(res.body.user.name, 'Ramesh Patel');
  });

  await t.test('POST /api/v1/products creates product with stock and barcode', async () => {
    const res = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Parle-G Gold 100g',
        barcode: '8901719101010',
        unit: 'packet',
        purchasePrice: 800,
        sellingPrice: 1000,
        currentStock: 50,
        minStock: 10
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.product.name, 'Parle-G Gold 100g');
    assert.equal(res.body.product.currentStock, 50);
    testProductId = res.body.product._id;
  });

  await t.test('GET /api/v1/products/barcode/:barcode finds product', async () => {
    const res = await request(app)
      .get('/api/v1/products/barcode/8901719101010')
      .set('Authorization', `Bearer ${authToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.product._id, testProductId);
  });

  await t.test('POST /api/v1/customers creates customer with opening balance', async () => {
    const res = await request(app)
      .post('/api/v1/customers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Suresh Kumar',
        mobile: '9876543210',
        openingBalance: 50000
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.customer.name, 'Suresh Kumar');
    assert.equal(res.body.customer.balance, 50000);
    testCustomerId = res.body.customer._id;
  });

  await t.test('POST /api/v1/bills creates a bill, deducts stock, and records credit', async () => {
    const res = await request(app)
      .post('/api/v1/bills')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        customerId: testCustomerId,
        items: [
          {
            productId: testProductId,
            name: 'Parle-G Gold 100g',
            unit: 'packet',
            qty: 5,
            rate: 1000,
            discount: 0
          }
        ],
        billDiscount: 0,
        paymentType: 'Credit',
        amountReceived: 0
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.bill.grandTotal, 5000);
    assert.equal(res.body.bill.balanceDue, 5000);

    const prodRes = await request(app)
      .get(`/api/v1/products/barcode/8901719101010`)
      .set('Authorization', `Bearer ${authToken}`);
    assert.equal(prodRes.body.product.currentStock, 45);

    const custRes = await request(app)
      .get(`/api/v1/customers/${testCustomerId}/ledger`)
      .set('Authorization', `Bearer ${authToken}`);
    assert.equal(custRes.body.customer.balance, 55000);
  });

  await t.test('GET /api/v1/reports/dashboard returns summary stats', async () => {
    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set('Authorization', `Bearer ${authToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.summary.todaySales, 5000);
    assert.equal(res.body.summary.pendingUdhaar, 55000);
  });

  await t.test('GET /api/v1/admin/stats returns platform stats for admin only', async () => {
    const deniedRes = await request(app)
      .get('/api/v1/admin/stats')
      .set('Authorization', `Bearer ${authToken}`);
    assert.equal(deniedRes.status, 403);

    const adminRes = await request(app)
      .get('/api/v1/admin/stats')
      .set('Authorization', `Bearer ${adminToken}`);
    assert.equal(adminRes.status, 200);
    assert.ok(adminRes.body.stats.totalUsers >= 2);
    assert.ok(adminRes.body.stats.totalShops >= 2);
  });

  await mongoose.connection.close();
});

