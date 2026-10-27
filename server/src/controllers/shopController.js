const Shop = require('../models/Shop');

exports.getShop = async (req, res) => {
  try {
    const shop = await Shop.findById(req.shopId);
    if (!shop) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Shop not found' });
    }
    return res.status(200).json({ success: true, shop });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

exports.updateShop = async (req, res) => {
  try {
    const { name, address, settings } = req.body;
    const shop = await Shop.findById(req.shopId);

    if (!shop) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'Shop not found' });
    }

    if (name) shop.name = name.trim();
    if (address !== undefined) shop.address = address.trim();
    if (settings) {
      shop.settings = { ...shop.settings, ...settings };
    }

    await shop.save();
    return res.status(200).json({ success: true, shop });
  } catch (err) {
    return res.status(500).json({ code: 'SERVER_ERROR', message: err.message });
  }
};

