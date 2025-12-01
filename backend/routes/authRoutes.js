const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken, isBoss } = require('../middleware/auth');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Protected routes
router.get('/me', verifyToken, authController.getMe);
router.get('/users', verifyToken, isBoss, authController.getAllUsers);

module.exports = router;
