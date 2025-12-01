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

// Socket.IO Connection
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  // Join office room
  socket.on('join_office', (data) => {
    const { officeId, userId } = data;
    socket.join(`office_${officeId}`);
    console.log(`User ${userId} joined office ${officeId}`);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Socket.IO ready for connections`);
});
