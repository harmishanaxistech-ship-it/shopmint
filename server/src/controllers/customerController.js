const Customer = require('../models/Customer');
const LedgerEntry = require('../models/LedgerEntry');

exports.getCustomers = async (req, res) => {
  try {
    const { search, hasBalance } = req.query;
    const query = { shopId: req.shopId, active: true };

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { mobile: { $regex: search, $options: 'i' } }
      ];
    }

    if (hasBalance === 'true') {
      query.balance = { $gt: 0 };
    }

    const customers = await Customer.find(query).sort({ balance: -1, updatedAt: -1 });

    const totalOutstanding = customers.reduce((sum, c) => sum + (c.balance > 0 ? c.balance : 0), 0);
    const countWithBalance = customers.filter(c => c.balance > 0).length;

    return res.status(200).json({
      success: true,
      totalOutstanding,
      countWithBalance,
      customers
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.createCustomer = async (req, res) => {
  try {
    const { name, mobile = '', address = '', openingBalance = 0 } = req.body;

    if (!name || name.trim().length < 2) {
      return res.status(400).json({
        code: 'INVALID_NAME',
        message: 'Customer name must be at least 2 characters.'
      });
    }

    if (mobile && mobile.trim()) {
      const existing = await Customer.findOne({
        shopId: req.shopId,
        mobile: mobile.trim(),
        active: true
      });
      if (existing) {
        return res.status(400).json({
          code: 'DUPLICATE_MOBILE',
          message: 'A customer with this mobile number already exists.'
        });
      }
    }

    const customer = new Customer({
      shopId: req.shopId,
      name: name.trim(),
      mobile: mobile ? mobile.trim() : '',
      address: address ? address.trim() : '',
      balance: Number(openingBalance)
    });

    await customer.save();

    if (Number(openingBalance) > 0) {
      await LedgerEntry.create({
        shopId: req.shopId,
        customerId: customer._id,
        type: 'opening',
        amount: Number(openingBalance),
        balanceAfter: Number(openingBalance),
        refType: 'Manual',
        note: 'Previous opening balance',
        createdBy: req.user._id
      });
    }

    return res.status(201).json({ success: true, customer });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.updateCustomer = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, mobile, address } = req.body;

    const customer = await Customer.findOne({ _id: id, shopId: req.shopId });
    if (!customer) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Customer not found' });
    }

    if (name) customer.name = name.trim();
    if (mobile !== undefined) customer.mobile = mobile.trim();
    if (address !== undefined) customer.address = address.trim();

    await customer.save();
    return res.status(200).json({ success: true, customer });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getCustomerLedger = async (req, res) => {
  try {
    const { id } = req.params;
    const customer = await Customer.findOne({ _id: id, shopId: req.shopId });
    if (!customer) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Customer not found' });
    }

    const entries = await LedgerEntry.find({
      shopId: req.shopId,
      customerId: id
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      customer,
      entries
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.receivePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, mode = 'Cash', note = '' } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        code: 'INVALID_AMOUNT',
        message: 'Amount must be greater than zero.'
      });
    }

    const customer = await Customer.findOne({ _id: id, shopId: req.shopId });
    if (!customer) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Customer not found' });
    }

    customer.balance -= Number(amount);
    await customer.save();

    const entry = await LedgerEntry.create({
      shopId: req.shopId,
      customerId: customer._id,
      type: 'payment',
      amount: Number(amount),
      balanceAfter: customer.balance,
      refType: 'Payment',
      note: note || `Payment received via ${mode}`,
      createdBy: req.user._id
    });

    return res.status(200).json({
      success: true,
      customer,
      entry
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.addCredit = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, note = '' } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        code: 'INVALID_AMOUNT',
        message: 'Credit amount must be greater than zero.'
      });
    }

    const customer = await Customer.findOne({ _id: id, shopId: req.shopId });
    if (!customer) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Customer not found' });
    }

    customer.balance += Number(amount);
    await customer.save();

    const entry = await LedgerEntry.create({
      shopId: req.shopId,
      customerId: customer._id,
      type: 'credit',
      amount: Number(amount),
      balanceAfter: customer.balance,
      refType: 'Manual',
      note: note || 'Manual Udhaar entry',
      createdBy: req.user._id
    });

    return res.status(200).json({
      success: true,
      customer,
      entry
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

