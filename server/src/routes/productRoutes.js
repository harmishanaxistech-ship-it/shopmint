const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { protect, ownerOnly } = require('../middlewares/auth');

router.get('/', protect, productController.getProducts);
router.get('/barcode/:barcode', protect, productController.getProductByBarcode);
router.post('/', protect, ownerOnly, productController.createProduct);
router.put('/:id', protect, ownerOnly, productController.updateProduct);
router.post('/:id/add-stock', protect, ownerOnly, productController.addStock);
router.post('/:id/adjust-stock', protect, ownerOnly, productController.adjustStock);

module.exports = router;

