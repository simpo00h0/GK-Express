const supabase = require('../config/supabase');

// Get all offices
exports.getAllOffices = async (req, res) => {
    try {
        const { data: offices, error } = await supabase
            .from('offices')
            .select('*')
            .order('name', { ascending: true });

        if (error) throw error;

        const formattedOffices = offices.map(office => ({
            id: office.id,
            name: office.name,
            country: office.country,
            countryCode: office.country_code,
            address: office.address,
            phone: office.phone,
            createdAt: office.created_at,
        }));

        res.json(formattedOffices);
    } catch (error) {
        console.error('Error fetching offices:', error);
        res.status(500).json({ message: 'Error fetching offices', error: error.message });
    }
};

// Get office by ID
exports.getOfficeById = async (req, res) => {
    try {
        const { id } = req.params;

        const { data: office, error } = await supabase
            .from('offices')
            .select('*')
            .eq('id', id)
            .single();

        if (error || !office) {
            return res.status(404).json({ message: 'Office not found' });
        }

        res.json({
            id: office.id,
            name: office.name,
            country: office.country,
            countryCode: office.country_code,
            address: office.address,
            phone: office.phone,
            createdAt: office.created_at,
        });
    } catch (error) {
        console.error('Error fetching office:', error);
        res.status(500).json({ message: 'Error fetching office', error: error.message });
    }
};
