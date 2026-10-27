const User = require('../models/User');
const Shop = require('../models/Shop');
const Bill = require('../models/Bill');
const Product = require('../models/Product');

exports.getSystemStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalShops = await Shop.countDocuments();
    const totalBills = await Bill.countDocuments({ status: 'active' });
    const totalProducts = await Product.countDocuments({ active: true });

    const bills = await Bill.find({ status: 'active' }, 'grandTotal');
    const totalVolume = bills.reduce((acc, b) => acc + (b.grandTotal || 0), 0);

    return res.status(200).json({
      success: true,
      stats: {
        totalUsers,
        totalShops,
        totalBills,
        totalProducts,
        totalVolume
      }
    });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getAllShops = async (req, res) => {
  try {
    const shops = await Shop.find().sort({ createdAt: -1 });
    const shopList = [];

    for (const s of shops) {
      const productCount = await Product.countDocuments({ shopId: s._id, active: true });
      const billCount = await Bill.countDocuments({ shopId: s._id, status: 'active' });
      shopList.push({
        ...s.toObject(),
        productCount,
        billCount
      });
    }

    return res.status(200).json({ success: true, shops: shopList });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select('-pin').sort({ createdAt: -1 });
    return res.status(200).json({ success: true, users });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, role } = req.body;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'User not found' });
    }

    if (status) user.status = status;
    if (role) user.role = role;
    await user.save();

    return res.status(200).json({ success: true, user });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.updateShopByAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, ownerName, mobile, type, address, settings } = req.body;

    const shop = await Shop.findById(id);
    if (!shop) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Shop not found' });
    }

    if (name) shop.name = name.trim();
    if (ownerName) shop.ownerName = ownerName.trim();
    if (mobile) shop.mobile = mobile.trim();
    if (type) shop.type = type;
    if (address !== undefined) shop.address = address.trim();
    if (settings) shop.settings = { ...shop.settings, ...settings };

    await shop.save();
    return res.status(200).json({ success: true, shop });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

