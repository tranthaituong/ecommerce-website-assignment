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

// API đăng nhập
app.post('/api/login', async (req, res) => {
    const { TenDangNhap, MatKhau } = req.body;

    if (!TenDangNhap || !MatKhau) {
        return res.status(400).json({ message: 'TenDangNhap và MatKhau là bắt buộc.' });
    }

    try {
        const request = new sql.Request();
        request.input('TenDangNhap', sql.VarChar(50), TenDangNhap);
        request.input('MatKhau', sql.NVarChar(255), MatKhau);

        const result = await request.query(`
            SELECT TenDangNhap, SDT, Email, VaiTro, NgayTao
            FROM TAI_KHOAN
            WHERE TenDangNhap = @TenDangNhap
              AND MatKhau = HASHBYTES('SHA2_256', @MatKhau)
        `);

        if (result.recordset.length === 0) {
            return res.status(401).json({ message: 'Sai tên đăng nhập hoặc mật khẩu.' });
        }

        return res.json({
            message: 'Đăng nhập thành công.',
            user: result.recordset[0],
        });
    } catch (err) {
        return res.status(500).json({ message: err.message });
    }
});

// API đăng ký (atomic transaction cho TAI_KHOAN + KHACH_HANG)
app.post('/api/register', async (req, res) => {
    const { TenDangNhap, MatKhau, SDT, Email, HoTen } = req.body;

    if (!TenDangNhap || !MatKhau || !SDT || !Email || !HoTen) {
        return res.status(400).json({
            message: 'TenDangNhap, MatKhau, SDT, Email, HoTen là bắt buộc.',
        });
    }

    const transaction = new sql.Transaction();

    try {
        await transaction.begin();

        const request = new sql.Request(transaction);
        request.input('TenDangNhap', sql.VarChar(50), TenDangNhap);
        request.input('MatKhau', sql.NVarChar(255), MatKhau);
        request.input('SDT', sql.Char(10), SDT);
        request.input('Email', sql.VarChar(50), Email);
        request.input('HoTen', sql.NVarChar(50), HoTen);

        await request.query(`
            INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, NgayTao, SDT, Email, VaiTro)
            VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), CAST(GETDATE() AS DATE), @SDT, @Email, 'KhachHang');
        `);

        const customerResult = await request.query(`
            INSERT INTO KHACH_HANG (HoTen, TenDangNhap)
            OUTPUT INSERTED.KhachHangID, INSERTED.HoTen, INSERTED.DiemTichLuy, INSERTED.TenDangNhap
            VALUES (@HoTen, @TenDangNhap);
        `);

        await transaction.commit();

        return res.status(201).json({
            message: 'Đăng ký thành công.',
            customer: customerResult.recordset[0],
        });
    } catch (err) {
        if (transaction._aborted !== true) {
            await transaction.rollback();
        }
        return res.status(500).json({ message: err.message });
    }
});

// API profile: join KHACH_HANG và DIA_CHI_KH
app.get('/api/profile/:id', async (req, res) => {
    const { id } = req.params;
    const customerId = Number(id);

    if (!Number.isInteger(customerId)) {
        return res.status(400).json({ message: 'id phải là số nguyên.' });
    }

    try {
        const request = new sql.Request();
        request.input('KhachHangID', sql.Int, customerId);

        const result = await request.query(`
            SELECT
                kh.KhachHangID,
                kh.HoTen,
                kh.DiemTichLuy,
                tk.TenDangNhap,
                tk.SDT,
                tk.Email,
                tk.VaiTro,
                dckh.MaDiaChi,
                dckh.SoNha,
                dckh.Huyen,
                dckh.Tinh,
                dckh.SDT_Nhan,
                dckh.MacDinh
            FROM KHACH_HANG kh
            INNER JOIN TAI_KHOAN tk ON tk.TenDangNhap = kh.TenDangNhap
            LEFT JOIN DIA_CHI_KH dckh ON dckh.KhachHangID = kh.KhachHangID
            WHERE kh.KhachHangID = @KhachHangID
            ORDER BY dckh.MaDiaChi
        `);

        if (result.recordset.length === 0) {
            return res.status(404).json({ message: 'Không tìm thấy khách hàng.' });
        }

        const firstRow = result.recordset[0];
        const addresses = result.recordset
            .filter((row) => row.MaDiaChi !== null)
            .map((row) => ({
                MaDiaChi: row.MaDiaChi,
                SoNha: row.SoNha,
                Huyen: row.Huyen,
                Tinh: row.Tinh,
                SDT_Nhan: row.SDT_Nhan,
                MacDinh: row.MacDinh,
            }));

        return res.json({
            KhachHangID: firstRow.KhachHangID,
            HoTen: firstRow.HoTen,
            DiemTichLuy: firstRow.DiemTichLuy,
            TenDangNhap: firstRow.TenDangNhap,
            SDT: firstRow.SDT,
            Email: firstRow.Email,
            VaiTro: firstRow.VaiTro,
            DiaChi: addresses,
        });
    } catch (err) {
        return res.status(500).json({ message: err.message });
    }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});