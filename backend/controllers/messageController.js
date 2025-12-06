const supabase = require('../config/supabase');

// Créer un nouveau message
exports.createMessage = async (req, res) => {
    try {
        const { toOfficeId, subject, content, relatedParcelId } = req.body;
        const fromUserId = req.userId;
        
        if (!toOfficeId || !subject || !content) {
            return res.status(400).json({ 
                message: 'toOfficeId, subject et content sont requis' 
            });
        }

        // Récupérer l'office de l'utilisateur expéditeur
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('office_id')
            .eq('id', fromUserId)
            .single();

        if (userError || !userData) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const fromOfficeId = userData.office_id;

        if (!fromOfficeId) {
            return res.status(400).json({ 
                message: 'L\'utilisateur doit être associé à un bureau' 
            });
        }

        if (fromOfficeId === toOfficeId) {
            return res.status(400).json({ 
                message: 'Vous ne pouvez pas envoyer un message à votre propre bureau' 
            });
        }

        // Créer le message
        const { data: message, error } = await supabase
            .from('messages')
            .insert({
                from_office_id: fromOfficeId,
                to_office_id: toOfficeId,
                from_user_id: fromUserId,
                subject: subject,
                content: content,
                related_parcel_id: relatedParcelId || null,
            })
            .select(`
                *,
                from_office:offices!messages_from_office_id_fkey(
                    id,
                    name,
                    country
                ),
                to_office:offices!messages_to_office_id_fkey(
                    id,
                    name,
                    country
                ),
                from_user:users!messages_from_user_id_fkey(
                    id,
                    full_name,
                    email
                ),
                related_parcel:parcels!messages_related_parcel_id_fkey(
                    id,
                    sender_name,
                    receiver_name,
                    destination,
                    status
                )
            `)
            .single();

        if (error) throw error;

        console.log(`✅ Message créé: ${message.id} de ${fromOfficeId} vers ${toOfficeId}`);

        // Formater la réponse
        const formattedMessage = {
            id: message.id,
            fromOfficeId: message.from_office_id,
            toOfficeId: message.to_office_id,
            fromUserId: message.from_user_id,
            subject: message.subject,
            content: message.content,
            relatedParcelId: message.related_parcel_id,
            readAt: message.read_at,
            createdAt: message.created_at,
            updatedAt: message.updated_at,
            fromOffice: message.from_office ? {
                id: message.from_office.id,
                name: message.from_office.name,
                country: message.from_office.country,
            } : null,
            toOffice: message.to_office ? {
                id: message.to_office.id,
                name: message.to_office.name,
                country: message.to_office.country,
            } : null,
            fromUser: message.from_user ? {
                id: message.from_user.id,
                fullName: message.from_user.full_name,
                email: message.from_user.email,
            } : null,
            relatedParcel: message.related_parcel ? {
                id: message.related_parcel.id,
                senderName: message.related_parcel.sender_name,
                receiverName: message.related_parcel.receiver_name,
                destination: message.related_parcel.destination,
                status: message.related_parcel.status,
            } : null,
        };

        // Émettre un événement Socket.IO pour notifier le bureau destinataire
        const io = req.app.get('io');
        if (io) {
            io.to(`office_${toOfficeId}`).emit('new_message', formattedMessage);
            console.log(`📨 Notification Socket.IO envoyée au bureau ${toOfficeId}`);
        }

        res.status(201).json(formattedMessage);
    } catch (error) {
        console.error('Erreur lors de la création du message:', error);
        res.status(500).json({ 
            message: 'Erreur lors de la création du message', 
            error: error.message 
        });
    }
};

// Récupérer les messages reçus par le bureau de l'utilisateur
exports.getReceivedMessages = async (req, res) => {
    try {
        const userId = req.userId;

        // Récupérer l'office de l'utilisateur
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('office_id')
            .eq('id', userId)
            .single();

        if (userError || !userData || !userData.office_id) {
            return res.status(404).json({ message: 'Bureau non trouvé pour cet utilisateur' });
        }

        const officeId = userData.office_id;

        // Récupérer les messages reçus
        const { data: messages, error } = await supabase
            .from('messages')
            .select(`
                *,
                from_office:offices!messages_from_office_id_fkey(
                    id,
                    name,
                    country
                ),
                from_user:users!messages_from_user_id_fkey(
                    id,
                    full_name,
                    email
                ),
                related_parcel:parcels!messages_related_parcel_id_fkey(
                    id,
                    sender_name,
                    receiver_name,
                    destination,
                    status
                )
            `)
            .eq('to_office_id', officeId)
            .order('created_at', { ascending: false });

        if (error) throw error;

        const formattedMessages = (messages || []).map(msg => ({
            id: msg.id,
            fromOfficeId: msg.from_office_id,
            toOfficeId: msg.to_office_id,
            fromUserId: msg.from_user_id,
            subject: msg.subject,
            content: msg.content,
            relatedParcelId: msg.related_parcel_id,
            readAt: msg.read_at,
            createdAt: msg.created_at,
            updatedAt: msg.updated_at,
            fromOffice: msg.from_office ? {
                id: msg.from_office.id,
                name: msg.from_office.name,
                country: msg.from_office.country,
            } : null,
            fromUser: msg.from_user ? {
                id: msg.from_user.id,
                fullName: msg.from_user.full_name,
                email: msg.from_user.email,
            } : null,
            relatedParcel: msg.related_parcel ? {
                id: msg.related_parcel.id,
                senderName: msg.related_parcel.sender_name,
                receiverName: msg.related_parcel.receiver_name,
                destination: msg.related_parcel.destination,
                status: msg.related_parcel.status,
            } : null,
        }));

        res.json(formattedMessages);
    } catch (error) {
        console.error('Erreur lors de la récupération des messages reçus:', error);
        res.status(500).json({ 
            message: 'Erreur lors de la récupération des messages', 
            error: error.message 
        });
    }
};

// Récupérer les messages envoyés par le bureau de l'utilisateur
exports.getSentMessages = async (req, res) => {
    try {
        const userId = req.userId;

        // Récupérer l'office de l'utilisateur
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('office_id')
            .eq('id', userId)
            .single();

        if (userError || !userData || !userData.office_id) {
            return res.status(404).json({ message: 'Bureau non trouvé pour cet utilisateur' });
        }

        const officeId = userData.office_id;

        // Récupérer les messages envoyés
        const { data: messages, error } = await supabase
            .from('messages')
            .select(`
                *,
                to_office:offices!messages_to_office_id_fkey(
                    id,
                    name,
                    country
                ),
                from_user:users!messages_from_user_id_fkey(
                    id,
                    full_name,
                    email
                ),
                related_parcel:parcels!messages_related_parcel_id_fkey(
                    id,
                    sender_name,
                    receiver_name,
                    destination,
                    status
                )
            `)
            .eq('from_office_id', officeId)
            .order('created_at', { ascending: false });

        if (error) throw error;

        const formattedMessages = (messages || []).map(msg => ({
            id: msg.id,
            fromOfficeId: msg.from_office_id,
            toOfficeId: msg.to_office_id,
            fromUserId: msg.from_user_id,
            subject: msg.subject,
            content: msg.content,
            relatedParcelId: msg.related_parcel_id,
            readAt: msg.read_at,
            createdAt: msg.created_at,
            updatedAt: msg.updated_at,
            toOffice: msg.to_office ? {
                id: msg.to_office.id,
                name: msg.to_office.name,
                country: msg.to_office.country,
            } : null,
            fromUser: msg.from_user ? {
                id: msg.from_user.id,
                fullName: msg.from_user.full_name,
                email: msg.from_user.email,
            } : null,
            relatedParcel: msg.related_parcel ? {
                id: msg.related_parcel.id,
                senderName: msg.related_parcel.sender_name,
                receiverName: msg.related_parcel.receiver_name,
                destination: msg.related_parcel.destination,
                status: msg.related_parcel.status,
            } : null,
        }));

        res.json(formattedMessages);
    } catch (error) {
        console.error('Erreur lors de la récupération des messages envoyés:', error);
        res.status(500).json({ 
            message: 'Erreur lors de la récupération des messages', 
            error: error.message 
        });
    }
};

// Récupérer une conversation entre deux bureaux
exports.getConversation = async (req, res) => {
    try {
        const { officeId } = req.params;
        const userId = req.userId;

        // Récupérer l'office de l'utilisateur
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('office_id')
            .eq('id', userId)
            .single();

        if (userError || !userData || !userData.office_id) {
            return res.status(404).json({ message: 'Bureau non trouvé pour cet utilisateur' });
        }

        const currentOfficeId = userData.office_id;

        // Récupérer tous les messages entre les deux bureaux
        const { data: messages, error } = await supabase
            .from('messages')
            .select(`
                *,
                from_office:offices!messages_from_office_id_fkey(
                    id,
                    name,
                    country
                ),
                to_office:offices!messages_to_office_id_fkey(
                    id,
                    name,
                    country
                ),
                from_user:users!messages_from_user_id_fkey(
                    id,
                    full_name,
                    email
                ),
                related_parcel:parcels!messages_related_parcel_id_fkey(
                    id,
                    sender_name,
                    receiver_name,
                    destination,
                    status
                )
            `)
            .or(`and(from_office_id.eq.${currentOfficeId},to_office_id.eq.${officeId}),and(from_office_id.eq.${officeId},to_office_id.eq.${currentOfficeId})`)
            .order('created_at', { ascending: true });

        if (error) throw error;

        const formattedMessages = (messages || []).map(msg => ({
            id: msg.id,
            fromOfficeId: msg.from_office_id,
            toOfficeId: msg.to_office_id,
            fromUserId: msg.from_user_id,
            subject: msg.subject,
            content: msg.content,
            relatedParcelId: msg.related_parcel_id,
            readAt: msg.read_at,
            createdAt: msg.created_at,
            updatedAt: msg.updated_at,
            fromOffice: msg.from_office ? {
                id: msg.from_office.id,
                name: msg.from_office.name,
                country: msg.from_office.country,
            } : null,
            toOffice: msg.to_office ? {
                id: msg.to_office.id,
                name: msg.to_office.name,
                country: msg.to_office.country,
            } : null,
            fromUser: msg.from_user ? {
                id: msg.from_user.id,
                fullName: msg.from_user.full_name,
                email: msg.from_user.email,
            } : null,
            relatedParcel: msg.related_parcel ? {
                id: msg.related_parcel.id,
                senderName: msg.related_parcel.sender_name,
                receiverName: msg.related_parcel.receiver_name,
                destination: msg.related_parcel.destination,
                status: msg.related_parcel.status,
            } : null,
        }));

        res.json(formattedMessages);
    } catch (error) {
        console.error('Erreur lors de la récupération de la conversation:', error);
        res.status(500).json({ 
            message: 'Erreur lors de la récupération de la conversation', 
            error: error.message 
        });
    }
};

// Marquer un message comme lu
exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.userId;

        // Vérifier que le message existe et appartient au bureau de l'utilisateur
        const { data: message, error: fetchError } = await supabase
            .from('messages')
            .select('to_office_id')
            .eq('id', id)
            .single();

        if (fetchError || !message) {
            return res.status(404).json({ message: 'Message non trouvé' });
        }

        // Récupérer l'office de l'utilisateur
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('office_id')
            .eq('id', userId)
            .single();

        if (userError || !userData || !userData.office_id) {
            return res.status(404).json({ message: 'Bureau non trouvé pour cet utilisateur' });
        }

        if (message.to_office_id !== userData.office_id) {
            return res.status(403).json({ 
                message: 'Vous n\'avez pas la permission de marquer ce message comme lu' 
            });
        }

        // Marquer comme lu
        const { data: updatedMessage, error } = await supabase
            .from('messages')
            .update({ read_at: new Date().toISOString() })
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;

        res.json({ 
            id: updatedMessage.id,
            readAt: updatedMessage.read_at 
        });
    } catch (error) {
        console.error('Erreur lors du marquage du message comme lu:', error);
        res.status(500).json({ 
            message: 'Erreur lors du marquage du message comme lu', 
            error: error.message 
        });
    }
};

// Récupérer le nombre de messages non lus
exports.getUnreadCount = async (req, res) => {
    try {
        const userId = req.userId;

        // Récupérer l'office de l'utilisateur
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('office_id')
            .eq('id', userId)
            .single();

        if (userError || !userData || !userData.office_id) {
            return res.status(404).json({ message: 'Bureau non trouvé pour cet utilisateur' });
        }

        const officeId = userData.office_id;

        // Compter les messages non lus
        const { count, error } = await supabase
            .from('messages')
            .select('*', { count: 'exact', head: true })
            .eq('to_office_id', officeId)
            .is('read_at', null);

        if (error) throw error;

        res.json({ unreadCount: count || 0 });
    } catch (error) {
        console.error('Erreur lors du comptage des messages non lus:', error);
        res.status(500).json({ 
            message: 'Erreur lors du comptage des messages non lus', 
            error: error.message 
        });
    }
};

