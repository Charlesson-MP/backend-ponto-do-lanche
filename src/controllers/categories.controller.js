const categoriesService = require('../services/categories.service');

const listCategories = async (req, res, next) => {
  try {
    const categories = await categoriesService.listCategories();
    return res.json({ success: true, data: categories });
  } catch (err) {
    next(err);
  }
};

module.exports = { listCategories };
