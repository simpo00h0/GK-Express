const { v4: uuidv4 } = require('uuid');
const supabase = require('../config/supabase');

exports.getAllParcels = async (req, res) => {
    try {
        const { officeId } = req.query;
        const userRole = req.userRole;
        const userId = req.userId;

        console.log('=== GET PARCELS DEBUG ===');
        console.log('User ID:', userId);
        console.log('User Role:', userRole);
        console.log('Query Office ID:', officeId);

        // Get user's office if agent
        let userOfficeId = null;
        if (userRole === 'agent') {
            const { data: userData } = await supabase
                .from('users')
                .select('office_id')
                .eq('id', userId)
                .single();
            userOfficeId = userData?.office_id;
            console.log('Agent Office ID:', userOfficeId);
        }

        let query = supabase
            .from('parcels')
            .select('*')
            .order('created_at', { ascending: false });

        // Filter based on role
        if (userRole === 'agent' && userOfficeId) {
            // Agent sees only parcels from/to their office
            console.log('FILTERING FOR AGENT - Office:', userOfficeId);
            query = query.or(`origin_office_id.eq.${userOfficeId},destination_office_id.eq.${userOfficeId}`);
        } else if (userRole === 'boss' && officeId) {
            // Boss can filter by specific office
            console.log('FILTERING FOR BOSS - Office:', officeId);
            query = query.or(`origin_office_id.eq.${officeId},destination_office_id.eq.${officeId}`);
        } else {
            console.log('NO FILTERING - Showing all parcels');
        }
        // If boss without filter, show all parcels

        const { data, error } = await query;

        if (error) throw error;

        console.log('Parcels found:', data?.length || 0);

        // Convert snake_case to camelCase for Flutter
        const parcels = (data || []).map(parcel => ({
            id: parcel.id,
            senderName: parcel.sender_name,
            senderPhone: parcel.sender_phone,
            receiverName: parcel.receiver_name,
            receiverPhone: parcel.receiver_phone,
            destination: parcel.destination,
            status: parcel.status,
            createdAt: parcel.created_at,
            price: parcel.price || 0,
            isPaid: parcel.is_paid || false,
            originOfficeId: parcel.origin_office_id,
            destinationOfficeId: parcel.destination_office_id,
            paidAtOfficeId: parcel.paid_at_office_id,
        }));

        res.json(parcels);
    } catch (error) {
        console.error('Error fetching parcels:', error);
        res.status(500).json({ message: 'Error fetching parcels', error: error.message });
    }
};

exports.createParcel = async (req, res) => {
    try {
        const { senderName, senderPhone, receiverName, receiverPhone, destination, price, isPaid, originOfficeId, destinationOfficeId } = req.body;

        if (!senderName || !receiverName || !destination || !originOfficeId || !destinationOfficeId) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        const newParcel = {
            id: uuidv4(),
            sender_name: senderName,
            sender_phone: senderPhone,
            receiver_name: receiverName,
            receiver_phone: receiverPhone,
            destination: destination,
            status: 'created',
            created_at: new Date().toISOString(),
            price: price || 0,
            is_paid: isPaid || false,
            origin_office_id: originOfficeId,
            destination_office_id: destinationOfficeId,
            paid_at_office_id: isPaid ? originOfficeId : null, // If paid at creation, paid at origin
            created_by_user_id: req.userId,
        };

        const { data, error } = await supabase
            .from('parcels')
            .insert([newParcel])
            .select()
            .single();

        if (error) throw error;

        res.status(201).json({
            id: data.id,
            senderName: data.sender_name,
            senderPhone: data.sender_phone,
            receiverName: data.receiver_name,
            receiverPhone: data.receiver_phone,
            destination: data.destination,
            status: data.status,
            createdAt: data.created_at,
            price: data.price,
            isPaid: data.is_paid,
            originOfficeId: data.origin_office_id,
            destinationOfficeId: data.destination_office_id,
            paidAtOfficeId: data.paid_at_office_id,
        });

        // Emit Socket.IO event to destination office
        const io = req.app.get('io');
        if (io && destinationOfficeId) {
            io.to(`office_${destinationOfficeId}`).emit('new_parcel', {
                parcelId: data.id,
                senderName: data.sender_name,
                destination: data.destination,
                originOfficeId: data.origin_office_id,
                destinationOfficeId: data.destination_office_id,
            });
            console.log(`📬 Notification sent to office ${destinationOfficeId}`);
        }
    } catch (error) {
        console.error('Error creating parcel:', error);
        res.status(500).json({ message: 'Error creating parcel', error: error.message });
    }
};

exports.updateParcelStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!status) {
            return res.status(400).json({ message: 'Status is required' });
        }

        // Get current parcel data
        const { data: currentParcel } = await supabase
            .from('parcels')
            .select('*')
            .eq('id', id)
            .single();

        const updateData = {
            status: status,
        };

        // If delivered and not paid yet, mark as paid at destination
        if (status === 'delivered' && !currentParcel.is_paid) {
            updateData.is_paid = true;
            updateData.paid_at_office_id = currentParcel.destination_office_id;
        }

        const { data, error } = await supabase
            .from('parcels')
            .update(updateData)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;

        res.json({
            id: data.id,
            senderName: data.sender_name,
            senderPhone: data.sender_phone,
            receiverName: data.receiver_name,
            receiverPhone: data.receiver_phone,
            destination: data.destination,
            status: data.status,
            createdAt: data.created_at,
            price: data.price,
            isPaid: data.is_paid,
            originOfficeId: data.origin_office_id,
            destinationOfficeId: data.destination_office_id,
            paidAtOfficeId: data.paid_at_office_id,
        });
    } catch (error) {
        console.error('Error updating parcel status:', error);
        res.status(500).json({ message: 'Error updating parcel status', error: error.message });
    }
};
