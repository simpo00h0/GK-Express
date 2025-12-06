const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const { verifyToken } = require('../middleware/auth');

// Créer un nouveau message
router.post('/', verifyToken, messageController.createMessage);

// Récupérer les messages reçus
router.get('/received', verifyToken, messageController.getReceivedMessages);

// Récupérer les messages envoyés
router.get('/sent', verifyToken, messageController.getSentMessages);

// Récupérer une conversation avec un bureau spécifique
router.get('/conversation/:officeId', verifyToken, messageController.getConversation);

// Marquer un message comme lu
router.patch('/:id/read', verifyToken, messageController.markAsRead);

// Récupérer le nombre de messages non lus
router.get('/unread/count', verifyToken, messageController.getUnreadCount);

module.exports = router;

