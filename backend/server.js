require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PATCH", "DELETE"]
  }
});

// Make io accessible to routes
app.set('io', io);

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const parcelRoutes = require('./routes/parcelRoutes');
const authRoutes = require('./routes/authRoutes');
const officeRoutes = require('./routes/officeRoutes');

app.use('/api/parcels', parcelRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/offices', officeRoutes);

// Root Endpoint
app.get('/', (req, res) => {
  res.send('GK Express Backend is Running');
});

// Track online users
const onlineUsers = new Map(); // socketId -> { userId, role }

// Socket.IO Connection
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  // Join office room
  socket.on('join_office', (data) => {
    const { officeId, userId } = data;
    socket.join(`office_${officeId}`);
    console.log(`User ${userId} joined office ${officeId}`);
  });

  // User comes online
  socket.on('user_online', (data) => {
    const { userId, role } = data;
    onlineUsers.set(socket.id, { userId, role });
    console.log(`User ${userId} is now online (${role})`);

    // Broadcast to all clients
    io.emit('user_connected', { userId });

    // Send current online users list
    const onlineUserIds = Array.from(onlineUsers.values()).map(u => u.userId);
    socket.emit('presence_update', { onlineUserIds });
  });

  // Request online users list
  socket.on('get_online_users', () => {
    const onlineUserIds = Array.from(onlineUsers.values()).map(u => u.userId);
    socket.emit('presence_update', { onlineUserIds });
  });

  socket.on('disconnect', () => {
    const userData = onlineUsers.get(socket.id);
    if (userData) {
      console.log(`User ${userData.userId} went offline`);
      onlineUsers.delete(socket.id);
      // Broadcast to all clients
      io.emit('user_disconnected', { userId: userData.userId });
    }
    console.log('Client disconnected:', socket.id);
  });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Socket.IO ready for connections`);
});
