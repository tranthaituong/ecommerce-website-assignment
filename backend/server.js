const express = require('express');
const sql = require('mssql/msnodesqlv8'); // Dùng driver cho Windows Auth
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Cấu hình lấy từ file .env
const config = {
    connectionString: process.env.DB_CONNECTION_STRING,
};

// Hàm kết nối Database
async function connectDB() {
    try {
        await sql.connect(config);
        console.log("✅ Đã kết nối SQL Server thành công (Windows Auth)!");
    } catch (err) {
        console.error("❌ Lỗi kết nối DB:", err.message);
    }
}

connectDB();

// API mẫu để lấy dữ liệu
app.get('/users', async (req, res) => {
    try {
        const result = await sql.query`SELECT * FROM TAI_KHOAN`; // Thay Users bằng tên bảng của bạn
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});