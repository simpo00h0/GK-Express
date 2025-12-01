const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Register new user (Boss or Agent)
exports.register = async (req, res) => {
    try {
        const { email, password, fullName, role, officeId } = req.body;

        // Validation
        if (!email || !password || !fullName || !role) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        if (role !== 'boss' && role !== 'agent') {
            return res.status(400).json({ message: 'Invalid role' });
        }

        if (role === 'agent' && !officeId) {
            return res.status(400).json({ message: 'Office ID required for agents' });
        }

        // Check if email already exists
        const { data: existingUser } = await supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .single();

        if (existingUser) {
            return res.status(409).json({ message: 'Email already registered' });
        }

        // Hash password
        const passwordHash = await bcrypt.hash(password, 10);

        // Create user
        const { data: newUser, error } = await supabase
            .from('users')
            .insert({
                email,
                password_hash: passwordHash,
                full_name: fullName,
                role,
                office_id: officeId || null,
            })
            .select()
            .single();

        if (error) throw error;

        // Generate JWT token
        const token = jwt.sign(
            { userId: newUser.id, email: newUser.email, role: newUser.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            token,
            user: {
                id: newUser.id,
                email: newUser.email,
                fullName: newUser.full_name,
                role: newUser.role,
                officeId: newUser.office_id,
            },
        });
    } catch (error) {
        console.error('Error registering user:', error);
        res.status(500).json({ message: 'Error registering user', error: error.message });
    }
};

// Login
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password required' });
        }

        // Find user
        const { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('email', email)
            .single();

        if (error || !user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Verify password
        const isValidPassword = await bcrypt.compare(password, user.password_hash);

        if (!isValidPassword) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Generate JWT token
        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                fullName: user.full_name,
                role: user.role,
                officeId: user.office_id,
            },
        });
    } catch (error) {
        console.error('Error logging in:', error);
        res.status(500).json({ message: 'Error logging in', error: error.message });
    }
};

// Get current user profile
exports.getMe = async (req, res) => {
    try {
        const userId = req.userId; // Set by auth middleware

        const { data: user, error } = await supabase
            .from('users')
            .select('id, email, full_name, role, office_id')
            .eq('id', userId)
            .single();

        if (error || !user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.json({
            id: user.id,
            email: user.email,
            fullName: user.full_name,
            role: user.role,
            officeId: user.office_id,
        });
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ message: 'Error fetching user', error: error.message });
    }
};

// Get all users (Boss only)
exports.getAllUsers = async (req, res) => {
    try {
        const { data: users, error } = await supabase
            .from('users')
            .select('id, email, full_name, role, office_id, created_at')
            .order('created_at', { ascending: false });

        if (error) throw error;

        const formattedUsers = users.map(user => ({
            id: user.id,
            email: user.email,
            fullName: user.full_name,
            role: user.role,
            officeId: user.office_id,
            createdAt: user.created_at,
        }));

        res.json(formattedUsers);
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ message: 'Error fetching users', error: error.message });
    }
};
