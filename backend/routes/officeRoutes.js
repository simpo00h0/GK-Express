const express = require('express');
const router = express.Router();
const officeController = require('../controllers/officeController');
const { verifyToken } = require('../middleware/auth');

// Public route for registration
router.get('/', officeController.getAllOffices);
router.get('/:id', verifyToken, officeController.getOfficeById);

module.exports = router;
