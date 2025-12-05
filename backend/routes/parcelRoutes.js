const express = require('express');
const router = express.Router();
const parcelController = require('../controllers/parcelController');
const { verifyToken } = require('../middleware/auth');

// All parcel routes require authentication
router.get('/', verifyToken, parcelController.getAllParcels);
router.post('/', verifyToken, parcelController.createParcel);
router.patch('/:id/status', verifyToken, parcelController.updateParcelStatus);
router.get('/:id/history', verifyToken, parcelController.getParcelStatusHistory);

module.exports = router;
