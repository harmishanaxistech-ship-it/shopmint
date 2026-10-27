const Product = require('../models/Product');
const StockMovement = require('../models/StockMovement');

exports.getProducts = async (req, res) => {
  try {
    const { search, lowStock, isLoose, page = 1, limit = 50 } = req.query;
    const query = { shopId: req.shopId, active: true };

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { barcode: search.trim() }
      ];
    }

    if (isLoose !== undefined) {
      query.isLoose = isLoose === 'true';
    }

    if (lowStock === 'true') {
      query.$expr = { $lte: ['$currentStock', '$minStock'] };
    }

    const total = await Product.countDocuments(query);
    const products = await Product.find(query)
      .sort({ updatedAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    return res.status(200).json({
      success: true,
      total,
      page: Number(page),
      limit: Number(limit),
      products
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getProductByBarcode = async (req, res) => {
  try {
    const { barcode } = req.params;
    const product = await Product.findOne({
      shopId: req.shopId,
      barcode: barcode.trim(),
      active: true
    });

    if (!product) {
      return res.status(404).json({
        code: 'NOT_FOUND',
        message: 'No product found for this barcode.'
      });
    }

    return res.status(200).json({ success: true, product });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.createProduct = async (req, res) => {
  try {
    const {
      name,
      barcode,
      unit = 'pcs',
      purchasePrice = 0,
      sellingPrice,
      currentStock = 0,
      minStock = 0,
      isLoose = false,
      imageUrl = ''
    } = req.body;

    if (!name || sellingPrice === undefined) {
      return res.status(400).json({
        code: 'MISSING_FIELDS',
        message: 'Product name and selling price are required.'
      });
    }

    if (barcode && barcode.trim()) {
      const existing = await Product.findOne({
        shopId: req.shopId,
        barcode: barcode.trim(),
        active: true
      });
      if (existing) {
        return res.status(400).json({
          code: 'DUPLICATE_BARCODE',
          message: 'A product with this barcode already exists in your shop.'
        });
      }
    }

    const product = new Product({
      shopId: req.shopId,
      name: name.trim(),
      barcode: barcode ? barcode.trim() : '',
      unit,
      purchasePrice: Number(purchasePrice),
      sellingPrice: Number(sellingPrice),
      currentStock: Number(currentStock),
      minStock: Number(minStock),
      isLoose: Boolean(isLoose),
      imageUrl: imageUrl.trim()
    });

    await product.save();

    if (currentStock > 0) {
      await StockMovement.create({
        shopId: req.shopId,
        productId: product._id,
        type: 'opening',
        quantityChange: Number(currentStock),
        balanceAfter: Number(currentStock),
        refType: 'None',
        note: 'Opening stock',
        createdBy: req.user._id
      });
    }

    return res.status(201).json({ success: true, product });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, barcode, unit, purchasePrice, sellingPrice, minStock, isLoose, imageUrl, active } = req.body;

    const product = await Product.findOne({ _id: id, shopId: req.shopId });
    if (!product) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Product not found' });
    }

    if (name) product.name = name.trim();
    if (barcode !== undefined) product.barcode = barcode.trim();
    if (unit) product.unit = unit;
    if (purchasePrice !== undefined) product.purchasePrice = Number(purchasePrice);
    if (sellingPrice !== undefined) product.sellingPrice = Number(sellingPrice);
    if (minStock !== undefined) product.minStock = Number(minStock);
    if (isLoose !== undefined) product.isLoose = Boolean(isLoose);
    if (imageUrl !== undefined) product.imageUrl = imageUrl.trim();
    if (active !== undefined) product.active = Boolean(active);

    await product.save();
    return res.status(200).json({ success: true, product });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.addStock = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity, newPurchasePrice, note } = req.body;

    if (!quantity || quantity <= 0) {
      return res.status(400).json({
        code: 'INVALID_QUANTITY',
        message: 'Quantity must be greater than zero.'
      });
    }

    const product = await Product.findOne({ _id: id, shopId: req.shopId });
    if (!product) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Product not found' });
    }

    product.currentStock += Number(quantity);
    if (newPurchasePrice !== undefined && newPurchasePrice >= 0) {
      product.purchasePrice = Number(newPurchasePrice);
    }
    await product.save();

    await StockMovement.create({
      shopId: req.shopId,
      productId: product._id,
      type: 'purchase',
      quantityChange: Number(quantity),
      balanceAfter: product.currentStock,
      refType: 'Restock',
      note: note || 'Stock added',
      createdBy: req.user._id
    });

    return res.status(200).json({ success: true, product });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.adjustStock = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantityChange, reason = 'Count correction', note } = req.body;

    if (quantityChange === 0 || quantityChange === undefined) {
      return res.status(400).json({
        code: 'INVALID_CHANGE',
        message: 'Quantity change cannot be zero.'
      });
    }

    const product = await Product.findOne({ _id: id, shopId: req.shopId });
    if (!product) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Product not found' });
    }

    product.currentStock += Number(quantityChange);
    await product.save();

    await StockMovement.create({
      shopId: req.shopId,
      productId: product._id,
      type: 'adjustment',
      quantityChange: Number(quantityChange),
      balanceAfter: product.currentStock,
      refType: 'Adjustment',
      reason,
      note: note || reason,
      createdBy: req.user._id
    });

    return res.status(200).json({ success: true, product });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

