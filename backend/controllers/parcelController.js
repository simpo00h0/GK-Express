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

        // Log initial status creation in history
        const initialHistoryEntry = {
            id: uuidv4(),
            parcel_id: data.id,
            old_status: null,
            new_status: 'created',
            changed_by_user_id: req.userId,
            office_id: originOfficeId,
            notes: 'Colis créé',
            changed_at: new Date().toISOString(),
        };

        const { error: historyError } = await supabase
            .from('parcel_status_history')
            .insert([initialHistoryEntry]);

        if (historyError) {
            console.error('Error logging initial status history:', historyError);
        } else {
            console.log('✅ Initial status history logged for parcel:', data.id);
        }

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
        let { status, notes } = req.body;

        if (!status) {
            return res.status(400).json({ message: 'Status is required' });
        }

        // Normalize status to lowercase
        status = status.toLowerCase();

        // Get current parcel data
        const { data: currentParcel, error: fetchError } = await supabase
            .from('parcels')
            .select('*')
            .eq('id', id)
            .single();

        if (fetchError || !currentParcel) {
            return res.status(404).json({ message: 'Parcel not found' });
        }

        const oldStatus = currentParcel.status;
        const updateData = {
            status: status,
        };

        // If delivered and not paid yet, mark as paid at destination
        if (status === 'delivered' && !currentParcel.is_paid) {
            updateData.is_paid = true;
            updateData.paid_at_office_id = currentParcel.destination_office_id;
        }

        // Update parcel status
        const { data, error } = await supabase
            .from('parcels')
            .update(updateData)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;

        // Get user's office for history
        let userOfficeId = null;
        if (req.userId) {
            const { data: userData } = await supabase
                .from('users')
                .select('office_id')
                .eq('id', req.userId)
                .single();
            userOfficeId = userData?.office_id;
        }

        // Log status change in history (only if status actually changed)
        if (oldStatus !== status) {
            try {
                const historyEntry = {
                    id: uuidv4(),
                    parcel_id: id,
                    old_status: oldStatus,
                    new_status: status,
                    changed_by_user_id: req.userId,
                    office_id: userOfficeId,
                    notes: notes || null,
                    changed_at: new Date().toISOString(),
                };

                const { error: historyError } = await supabase
                    .from('parcel_status_history')
                    .insert([historyEntry]);

                if (historyError) {
                    console.error('⚠️ Error logging status history (non-blocking):', historyError.message);
                    // Don't fail the request if history logging fails
                    // This allows the system to work even if the history table doesn't exist yet
                } else {
                    console.log(`✅ Status history logged: ${oldStatus} → ${status}`);
                }
            } catch (historyErr) {
                console.error('⚠️ Exception while logging status history (non-blocking):', historyErr.message);
                // Continue even if history logging fails
            }
        }

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

// Get parcel status history
exports.getParcelStatusHistory = async (req, res) => {
    try {
        const { id } = req.params;

        // Get history with user and office information
        const { data: history, error } = await supabase
            .from('parcel_status_history')
            .select(`
                *,
                changed_by_user:users!parcel_status_history_changed_by_user_id_fkey(
                    id,
                    full_name,
                    email
                ),
                office:offices!parcel_status_history_office_id_fkey(
                    id,
                    name,
                    country
                )
            `)
            .eq('parcel_id', id)
            .order('changed_at', { ascending: false });

        if (error) throw error;

        // Format response
        const formattedHistory = (history || []).map(entry => ({
            id: entry.id,
            parcelId: entry.parcel_id,
            oldStatus: entry.old_status,
            newStatus: entry.new_status,
            changedByUserId: entry.changed_by_user_id,
            changedByUserName: entry.changed_by_user?.full_name || 'Utilisateur inconnu',
            changedByUserEmail: entry.changed_by_user?.email || null,
            officeId: entry.office_id,
            officeName: entry.office?.name || null,
            officeCountry: entry.office?.country || null,
            notes: entry.notes,
            changedAt: entry.changed_at,
        }));

        res.json(formattedHistory);
    } catch (error) {
        console.error('Error fetching parcel status history:', error);
        res.status(500).json({ message: 'Error fetching parcel status history', error: error.message });
    }
};
