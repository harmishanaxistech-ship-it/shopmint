const Bill = require('../models/Bill');
const Customer = require('../models/Customer');
const Product = require('../models/Product');

exports.getDashboardSummary = async (req, res) => {
  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayBills = await Bill.find({
      shopId: req.shopId,
      status: 'active',
      createdAt: { $gte: todayStart }
    });

    let todaySales = 0;
    let todayCost = 0;

    for (const b of todayBills) {
      todaySales += b.grandTotal;
      for (const item of b.items) {
        todayCost += (item.purchasePrice || 0) * item.qty;
      }
    }

    const todayProfit = Math.max(0, todaySales - todayCost);

    const customersWithBalance = await Customer.find({
      shopId: req.shopId,
      active: true,
      balance: { $gt: 0 }
    });
    const pendingUdhaar = customersWithBalance.reduce((acc, c) => acc + c.balance, 0);

    const lowStockCount = await Product.countDocuments({
      shopId: req.shopId,
      active: true,
      $expr: { $lte: ['$currentStock', '$minStock'] }
    });

    const recentBills = await Bill.find({ shopId: req.shopId })
      .sort({ createdAt: -1 })
      .limit(5);

    return res.status(200).json({
      success: true,
      summary: {
        todaySales,
        todayProfit,
        pendingUdhaar,
        lowStockCount,
        recentBills
      }
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getSalesOverview = async (req, res) => {
  try {
    const { from, to } = req.query;
    const query = { shopId: req.shopId, status: 'active' };

    if (from || to) {
      query.createdAt = {};
      if (from) query.createdAt.$gte = new Date(from);
      if (to) {
        const toDate = new Date(to);
        toDate.setHours(23, 59, 59, 999);
        query.createdAt.$lte = toDate;
      }
    }

    const bills = await Bill.find(query).sort({ createdAt: -1 });

    let totalBilled = 0;
    let cashReceived = 0;
    let upiReceived = 0;
    let otherReceived = 0;
    let creditGiven = 0;

    for (const b of bills) {
      totalBilled += b.grandTotal;
      if (b.paymentType === 'Cash') cashReceived += b.amountReceived;
      if (b.paymentType === 'UPI') upiReceived += b.amountReceived;
      if (b.paymentType === 'Other') otherReceived += b.amountReceived;
      creditGiven += b.balanceDue;
    }

    return res.status(200).json({
      success: true,
      totalBills: bills.length,
      totalBilled,
      cashReceived,
      upiReceived,
      otherReceived,
      creditGiven,
      bills
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getProfitReport = async (req, res) => {
  try {
    const { from, to } = req.query;
    const query = { shopId: req.shopId, status: 'active' };

    if (from || to) {
      query.createdAt = {};
      if (from) query.createdAt.$gte = new Date(from);
      if (to) {
        const toDate = new Date(to);
        toDate.setHours(23, 59, 59, 999);
        query.createdAt.$lte = toDate;
      }
    }

    const bills = await Bill.find(query);

    let revenue = 0;
    let costOfGoodsSold = 0;

    for (const b of bills) {
      revenue += b.grandTotal;
      for (const item of b.items) {
        costOfGoodsSold += (item.purchasePrice || 0) * item.qty;
      }
    }

    const grossProfit = Math.max(0, revenue - costOfGoodsSold);
    const profitPercent = revenue > 0 ? Number(((grossProfit / revenue) * 100).toFixed(2)) : 0;

    return res.status(200).json({
      success: true,
      revenue,
      costOfGoodsSold,
      grossProfit,
      profitPercent
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getBestSellers = async (req, res) => {
  try {
    const { from, to } = req.query;
    const query = { shopId: req.shopId, status: 'active' };

    if (from || to) {
      query.createdAt = {};
      if (from) query.createdAt.$gte = new Date(from);
      if (to) {
        const toDate = new Date(to);
        toDate.setHours(23, 59, 59, 999);
        query.createdAt.$lte = toDate;
      }
    }

    const bills = await Bill.find(query);
    const itemMap = {};

    for (const b of bills) {
      for (const item of b.items) {
        const key = item.productId ? item.productId.toString() : item.name;
        if (!itemMap[key]) {
          itemMap[key] = {
            productId: item.productId,
            name: item.name,
            unit: item.unit,
            totalQty: 0,
            revenue: 0,
            cost: 0
          };
        }
        itemMap[key].totalQty += item.qty;
        itemMap[key].revenue += item.amount;
        itemMap[key].cost += (item.purchasePrice || 0) * item.qty;
      }
    }

    const bestSellers = Object.values(itemMap)
      .map(item => ({
        ...item,
        profit: Math.max(0, item.revenue - item.cost)
      }))
      .sort((a, b) => b.totalQty - a.totalQty)
      .slice(0, 20);

    return res.status(200).json({
      success: true,
      bestSellers
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

