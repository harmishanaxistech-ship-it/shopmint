const Bill = require('../models/Bill');
const Product = require('../models/Product');
const Customer = require('../models/Customer');
const StockMovement = require('../models/StockMovement');
const LedgerEntry = require('../models/LedgerEntry');

const generateBillNumber = async (shopId) => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const prefix = `B-${year}${month}${day}-`;

  const lastBill = await Bill.findOne({
    shopId,
    billNo: { $regex: `^${prefix}` }
  }).sort({ billNo: -1 });

  let seq = 1;
  if (lastBill) {
    const parts = lastBill.billNo.split('-');
    if (parts.length === 3) {
      seq = parseInt(parts[2], 10) + 1;
    }
  }

  return `${prefix}${String(seq).padStart(4, '0')}`;
};

exports.createBill = async (req, res) => {
  try {
    const {
      customerId,
      customerName,
      items,
      billDiscount = 0,
      paymentType = 'Cash',
      amountReceived,
      note = ''
    } = req.body;

    if (!items || !items.length) {
      return res.status(400).json({
        code: 'EMPTY_CART',
        message: 'Cart cannot be empty.'
      });
    }

    let subtotal = 0;
    const processedItems = [];

    for (const item of items) {
      const qty = Number(item.qty);
      const rate = Number(item.rate);
      const discount = Number(item.discount || 0);
      const lineAmount = Math.max(0, Math.round(qty * rate - discount));
      subtotal += lineAmount;

      let purchasePrice = 0;
      let itemImage = item.imageUrl || '';
      if (item.productId) {
        const prod = await Product.findOne({ _id: item.productId, shopId: req.shopId });
        if (prod) {
          if (!itemImage && prod.imageUrl) {
            itemImage = prod.imageUrl;
          }
          purchasePrice = prod.purchasePrice || 0;
          prod.currentStock -= qty;
          await prod.save();

          await StockMovement.create({
            shopId: req.shopId,
            productId: prod._id,
            type: 'sale',
            quantityChange: -qty,
            balanceAfter: prod.currentStock,
            refType: 'Bill',
            note: 'Sold on bill',
            createdBy: req.user._id
          });
        }
      }

      processedItems.push({
        productId: item.productId || null,
        name: item.name,
        unit: item.unit || 'pcs',
        qty,
        rate,
        purchasePrice,
        discount,
        imageUrl: itemImage,
        amount: lineAmount
      });
    }

    const discountTotal = Number(billDiscount);
    const unroundedTotal = Math.max(0, subtotal - discountTotal);
    const grandTotal = Math.round(unroundedTotal / 100) * 100;
    const roundOff = grandTotal - unroundedTotal;

    const received = paymentType === 'Credit' ? 0 : Number(amountReceived !== undefined ? amountReceived : grandTotal);
    const balanceDue = Math.max(0, grandTotal - received);

    if (balanceDue > 0 && !customerId) {
      const cName = (customerName && customerName.trim()) ? customerName.trim() : 'Customer';
      const cPhone = (req.body.customerPhone && req.body.customerPhone.trim()) ? req.body.customerPhone.trim() : '';

      let foundCustomer = null;
      if (cPhone) {
        foundCustomer = await Customer.findOne({ shopId: req.shopId, mobile: cPhone, active: true });
      }
      if (!foundCustomer && cName !== 'Customer' && cName !== 'Walk-in Customer') {
        foundCustomer = await Customer.findOne({ shopId: req.shopId, name: cName, active: true });
      }
      if (!foundCustomer) {
        foundCustomer = await Customer.create({
          shopId: req.shopId,
          name: cName,
          mobile: cPhone,
          balance: 0
        });
      }
      customerId = foundCustomer._id;
    }

    const billNo = await generateBillNumber(req.shopId);

    let customerDoc = null;
    if (customerId) {
      customerDoc = await Customer.findOne({ _id: customerId, shopId: req.shopId });
      if (customerDoc && balanceDue > 0) {
        customerDoc.balance += balanceDue;
        await customerDoc.save();

        await LedgerEntry.create({
          shopId: req.shopId,
          customerId: customerDoc._id,
          type: 'credit',
          amount: balanceDue,
          balanceAfter: customerDoc.balance,
          refType: 'Bill',
          note: `Credit on bill ${billNo}`,
          createdBy: req.user._id
        });
      }
    }

    const bill = new Bill({
      shopId: req.shopId,
      billNo,
      customerId: customerDoc ? customerDoc._id : null,
      customerName: customerDoc ? customerDoc.name : (customerName || 'Walk-in Customer'),
      items: processedItems,
      subtotal,
      billDiscount: discountTotal,
      roundOff,
      grandTotal,
      paymentType,
      amountReceived: received,
      balanceDue,
      note,
      createdBy: req.user._id
    });

    await bill.save();

    return res.status(201).json({
      success: true,
      bill
    });
  } catch (err) {
    console.error('Create bill error:', err);
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getBills = async (req, res) => {
  try {
    const { from, to, customerId, paymentType, status, search, page = 1, limit = 20 } = req.query;
    const query = { shopId: req.shopId };

    if (status) query.status = status;
    if (paymentType) query.paymentType = paymentType;
    if (customerId) query.customerId = customerId;

    if (search) {
      query.$or = [
        { billNo: { $regex: search, $options: 'i' } },
        { customerName: { $regex: search, $options: 'i' } }
      ];
    }

    if (from || to) {
      query.createdAt = {};
      if (from) query.createdAt.$gte = new Date(from);
      if (to) {
        const toDate = new Date(to);
        toDate.setHours(23, 59, 59, 999);
        query.createdAt.$lte = toDate;
      }
    }

    const total = await Bill.countDocuments(query);
    const bills = await Bill.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    return res.status(200).json({
      success: true,
      total,
      page: Number(page),
      limit: Number(limit),
      bills
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getBillById = async (req, res) => {
  try {
    const { id } = req.params;
    const bill = await Bill.findOne({ _id: id, shopId: req.shopId });

    if (!bill) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Bill not found' });
    }

    return res.status(200).json({ success: true, bill });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.cancelBill = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason = 'Cancelled by owner' } = req.body;

    const bill = await Bill.findOne({ _id: id, shopId: req.shopId });
    if (!bill) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Bill not found' });
    }

    if (bill.status === 'cancelled') {
      return res.status(400).json({
        code: 'ALREADY_CANCELLED',
        message: 'This bill has already been cancelled.'
      });
    }

    for (const item of bill.items) {
      if (item.productId) {
        const prod = await Product.findOne({ _id: item.productId, shopId: req.shopId });
        if (prod) {
          prod.currentStock += item.qty;
          await prod.save();

          await StockMovement.create({
            shopId: req.shopId,
            productId: prod._id,
            type: 'cancel',
            quantityChange: item.qty,
            balanceAfter: prod.currentStock,
            refType: 'Bill',
            note: `Cancelled bill ${bill.billNo}`,
            createdBy: req.user._id
          });
        }
      }
    }

    if (bill.customerId && bill.balanceDue > 0) {
      const customer = await Customer.findOne({ _id: bill.customerId, shopId: req.shopId });
      if (customer) {
        customer.balance -= bill.balanceDue;
        await customer.save();

        await LedgerEntry.create({
          shopId: req.shopId,
          customerId: customer._id,
          type: 'reversal',
          amount: bill.balanceDue,
          balanceAfter: customer.balance,
          refType: 'Bill',
          note: `Reversal for cancelled bill ${bill.billNo}`,
          createdBy: req.user._id
        });
      }
    }

    bill.status = 'cancelled';
    bill.cancelReason = reason;
    await bill.save();

    return res.status(200).json({
      success: true,
      message: 'Bill cancelled successfully and inventory restored.',
      bill
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

