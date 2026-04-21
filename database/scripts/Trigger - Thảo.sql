USE BTL;
GO

DROP TRIGGER IF EXISTS TRG_TinhThanhTien;
DROP TRIGGER IF EXISTS TRG_CapNhatTongTien;
DROP TRIGGER IF EXISTS TRG_CapNhatDiem_TonKho;
GO

-- Trigger tính ThanhTien
CREATE TRIGGER TRG_TinhThanhTien
ON CHI_TIET_DON_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    -- Chỉ chạy khi cột SoLuong hoặc GiaMotSP có sự thay đổi
    IF UPDATE(SoLuong) OR UPDATE(GiaMotSP)
    BEGIN
        UPDATE ct
        SET ct.ThanhTien = i.SoLuong * i.GiaMotSP
        FROM CHI_TIET_DON_HANG ct
        JOIN inserted i ON ct.MaDH = i.MaDH AND ct.MaSP = i.MaSP AND ct.MaBT = i.MaBT;
    END
END;
GO

-- Trigger tính TongTien
CREATE TRIGGER TRG_CapNhatTongTien
ON CHI_TIET_DON_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Cập nhật cho Đơn hàng bị ảnh hưởng bởi thao tác INSERT/UPDATE
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE dh
        SET dh.TongTien = (
            SELECT ISNULL(SUM(ThanhTien), 0)
            FROM CHI_TIET_DON_HANG ct
            WHERE ct.MaDH = dh.MaDH
        )
        FROM DON_HANG dh
        JOIN inserted i ON dh.MaDH = i.MaDH;
    END

    -- Cập nhật cho Đơn hàng bị ảnh hưởng bởi thao tác DELETE
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE dh
        SET dh.TongTien = (
            SELECT ISNULL(SUM(ThanhTien), 0)
            FROM CHI_TIET_DON_HANG ct
            WHERE ct.MaDH = dh.MaDH
        )
        FROM DON_HANG dh
        JOIN deleted d ON dh.MaDH = d.MaDH;
    END
END;
GO

-- Trigger cập nhật DiemTichLuy + SoLuong tồn kho
CREATE TRIGGER TRG_CapNhatDiem_TonKho
ON DON_HANG
AFTER UPDATE
AS
BEGIN
    IF UPDATE(TrangThaiDonHang)
    BEGIN        
        -- TRỪ KHO (Khi bắt đầu giao hàng)
        -- Trạng thái cũ: Chờ xử lý -> Trạng thái mới: Đang giao hàng
        UPDATE tk
        SET tk.SoLuong = tk.SoLuong - ct.SoLuong
        FROM TON_KHO tk
        JOIN inserted i ON tk.MaCuaHang = i.MaCuaHang
        JOIN deleted d ON i.MaDH = d.MaDH
        JOIN CHI_TIET_DON_HANG ct ON i.MaDH = ct.MaDH AND tk.MaSP = ct.MaSP AND tk.MaBT = ct.MaBT
        WHERE d.TrangThaiDonHang = N'Chờ xử lý' 
          AND i.TrangThaiDonHang = N'Đang giao hàng';

        -- CỘNG LẠI KHO (Khi đơn hàng bị hủy)
        -- Trạng thái cũ: Đang giao hàng hoặc Chờ xử lý -> Trạng thái mới: Đã hủy
        UPDATE tk
        SET tk.SoLuong = tk.SoLuong + ct.SoLuong
        FROM TON_KHO tk
        JOIN inserted i ON tk.MaCuaHang = i.MaCuaHang
        JOIN deleted d ON i.MaDH = d.MaDH
        JOIN CHI_TIET_DON_HANG ct ON i.MaDH = ct.MaDH AND tk.MaSP = ct.MaSP AND tk.MaBT = ct.MaBT
        WHERE (d.TrangThaiDonHang = N'Đang giao hàng' OR d.TrangThaiDonHang = N'Chờ xử lý')
          AND i.TrangThaiDonHang = N'Đã hủy';

        -- CỘNG ĐIỂM (Khi giao dịch thành công)
        -- Trạng thái cũ: Khác Hoàn thành -> Trạng thái mới: Hoàn thành
        UPDATE kh
        SET kh.DiemTichLuy = kh.DiemTichLuy + (i.TongTien / 1000)
        FROM KHACH_HANG kh
        JOIN inserted i ON kh.KhachHangID = i.KhachHangID
        JOIN deleted d ON i.MaDH = d.MaDH
        WHERE i.TrangThaiDonHang = N'Hoàn thành' 
          AND d.TrangThaiDonHang <> N'Hoàn thành';
    END
END;
GO


-- Câu lệnh minh họa
PRINT N'======================================================';
PRINT N'PHẦN 0: KHỞI TẠO DỮ LIỆU NỀN (CHẠY 1 LẦN)';
PRINT N'======================================================';
-- Tạo Khách hàng và Nhân viên
INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, NgayTao, SDT, Email, VaiTro) 
VALUES ('testkh', 0x1234, GETDATE(), '0900000001', 'kh@gmail.com', 'KhachHang'),
       ('testnv', 0x1234, GETDATE(), '0900000002', 'nv@gmail.com', 'NhanVien');

INSERT INTO KHACH_HANG (HoTen, DiemTichLuy, TenDangNhap) VALUES (N'Khách Hàng Vip', 0, 'testkh');
INSERT INTO NHAN_VIEN (CCCD, Luong, TenDangNhap) VALUES ('000000000001', 5000000, 'testnv');

-- Lấy ID
DECLARE @KH_ID INT = (SELECT TOP 1 KhachHangID FROM KHACH_HANG ORDER BY KhachHangID DESC);
DECLARE @NV_ID INT = (SELECT TOP 1 MaNhanVien FROM NHAN_VIEN ORDER BY MaNhanVien DESC);

-- Tạo Địa chỉ, Cửa hàng và Sản phẩm
INSERT INTO DIA_CHI_KH (MaDiaChi, KhachHangID, SoNha, Huyen, Tinh, SDT_Nhan) 
VALUES (99, @KH_ID, '12A', N'Quận 1', N'TP HCM', '0900000001');

INSERT INTO CUA_HANG (SDT, SoNha, Huyen, Tinh) VALUES ('0280000001', '15', N'Quận 1', N'TP HCM');
DECLARE @CH_ID INT = (SELECT TOP 1 MaCuaHang FROM CUA_HANG ORDER BY MaCuaHang DESC);

INSERT INTO LAM_VIEC (MaCuaHang, MaNhanVien) VALUES (@CH_ID, @NV_ID);

INSERT INTO SAN_PHAM (MaSP, TenSP, GiaSP, HangSanXuat) VALUES ('IP15', N'iPhone 15 Pro Max', 30000000, 'Apple');
INSERT INTO BIEN_THE_SAN_PHAM (MaSP, MaBT, MauSac) VALUES ('IP15', 'DEN', N'Đen');

-- NHẬP KHO: 100 chiếc
INSERT INTO TON_KHO (MaCuaHang, MaSP, MaBT, SoLuong) VALUES (@CH_ID, 'IP15', 'DEN', 100);
GO


PRINT N'======================================================';
PRINT N'SCENARIO 1: TEST TRIGGER 1 & 2 (TÍNH THÀNH TIỀN & TỔNG TIỀN)';
PRINT N'======================================================';
DECLARE @KH_ID INT = (SELECT TOP 1 KhachHangID FROM KHACH_HANG ORDER BY KhachHangID DESC);
DECLARE @NV_ID INT = (SELECT TOP 1 MaNhanVien FROM NHAN_VIEN ORDER BY MaNhanVien DESC);
DECLARE @CH_ID INT = (SELECT TOP 1 MaCuaHang FROM CUA_HANG ORDER BY MaCuaHang DESC);

-- 1. Tạo 1 Đơn hàng trống (Tổng tiền = 0)
INSERT INTO DON_HANG (KhachHangID, MaDiaChi, MaNhanVien, MaCuaHang, NgayDat, NgayNhanDuKien, TongTien, TrangThaiDonHang)
VALUES (@KH_ID, 99, @NV_ID, @CH_ID, GETDATE(), DATEADD(DAY, 3, GETDATE()), 0, N'Chờ xử lý');
DECLARE @DH1 INT = (SELECT MAX(MaDH) FROM DON_HANG);

-- 2. Thêm 2 điện thoại vào đơn -> Trigger 1 & 2 tự chạy
INSERT INTO CHI_TIET_DON_HANG (MaDH, MaSP, MaBT, SoLuong, GiaMotSP) 
VALUES (@DH1, 'IP15', 'DEN', 2, 30000000);

PRINT N'---> SAU KHI THÊM 2 SẢN PHẨM:';
-- KỲ VỌNG: Thành tiền = 60tr, Tổng đơn = 60tr
SELECT MaDH, MaSP, SoLuong, GiaMotSP, ThanhTien AS 'ThanhTien_TuTinh' FROM CHI_TIET_DON_HANG WHERE MaDH = @DH1;
SELECT MaDH, TongTien AS 'TongTien_TuTinh' FROM DON_HANG WHERE MaDH = @DH1;

-- 3. Đổi ý, khách chỉ mua 1 điện thoại
UPDATE CHI_TIET_DON_HANG SET SoLuong = 1 WHERE MaDH = @DH1 AND MaSP = 'IP15';

PRINT N'---> SAU KHI GIẢM XUỐNG 1 SẢN PHẨM:';
-- KỲ VỌNG: Tiền tụt xuống còn 30tr
SELECT MaDH, TongTien AS 'TongTien_GiamXuong' FROM DON_HANG WHERE MaDH = @DH1;
GO


PRINT N'======================================================';
PRINT N'SCENARIO 2: TEST TRIGGER 3 - LUỒNG THÀNH CÔNG (TRỪ KHO + CỘNG ĐIỂM)';
PRINT N'======================================================';
DECLARE @DH1 INT = (SELECT MAX(MaDH) FROM DON_HANG);
DECLARE @CH_ID INT = (SELECT MaCuaHang FROM DON_HANG WHERE MaDH = @DH1);
DECLARE @KH_ID INT = (SELECT KhachHangID FROM DON_HANG WHERE MaDH = @DH1);

PRINT N'---> 1. KHO VÀ ĐIỂM LÚC "CHỜ XỬ LÝ":';
SELECT MaSP, SoLuong AS 'TonKho_TruocKhiGiao' FROM TON_KHO WHERE MaCuaHang = @CH_ID AND MaSP = 'IP15'; -- Đang là 100
SELECT HoTen, DiemTichLuy AS 'Diem_TruocKhiGiao' FROM KHACH_HANG WHERE KhachHangID = @KH_ID; -- Đang là 0

PRINT N'---> 2. XUẤT KHO ĐI GIAO:';
UPDATE DON_HANG SET TrangThaiDonHang = N'Đang giao hàng' WHERE MaDH = @DH1;
-- KỲ VỌNG: Kho bị trừ 1, còn 99
SELECT MaSP, SoLuong AS 'TonKho_BiTru' FROM TON_KHO WHERE MaCuaHang = @CH_ID AND MaSP = 'IP15';

PRINT N'---> 3. GIAO THÀNH CÔNG (CỘNG ĐIỂM):';
UPDATE DON_HANG SET TrangThaiDonHang = N'Hoàn thành' WHERE MaDH = @DH1;
-- KỲ VỌNG: Khách được cộng 30.000 điểm (30tr / 1000)
SELECT HoTen, DiemTichLuy AS 'Diem_DuocCongThem' FROM KHACH_HANG WHERE KhachHangID = @KH_ID;
GO


PRINT N'======================================================';
PRINT N'SCENARIO 3: TEST TRIGGER 3 - LUỒNG HỦY ĐƠN (HOÀN LẠI KHO)';
PRINT N'======================================================';
DECLARE @KH_ID INT = (SELECT TOP 1 KhachHangID FROM KHACH_HANG ORDER BY KhachHangID DESC);
DECLARE @NV_ID INT = (SELECT TOP 1 MaNhanVien FROM NHAN_VIEN ORDER BY MaNhanVien DESC);
DECLARE @CH_ID INT = (SELECT TOP 1 MaCuaHang FROM CUA_HANG ORDER BY MaCuaHang DESC);

-- 1. Có một khách khác đặt mua 5 chiếc
INSERT INTO DON_HANG (KhachHangID, MaDiaChi, MaNhanVien, MaCuaHang, NgayDat, NgayNhanDuKien, TongTien, TrangThaiDonHang)
VALUES (@KH_ID, 99, @NV_ID, @CH_ID, GETDATE(), DATEADD(DAY, 3, GETDATE()), 0, N'Chờ xử lý');
DECLARE @DH_HUY INT = (SELECT MAX(MaDH) FROM DON_HANG);

INSERT INTO CHI_TIET_DON_HANG (MaDH, MaSP, MaBT, SoLuong, GiaMotSP) 
VALUES (@DH_HUY, 'IP15', 'DEN', 5, 30000000);

PRINT N'---> 1. XUẤT 5 CHIẾC ĐI GIAO (KHO TRỪ 5):';
UPDATE DON_HANG SET TrangThaiDonHang = N'Đang giao hàng' WHERE MaDH = @DH_HUY;
-- KỲ VỌNG: Kho từ 99 tụt xuống 94
SELECT MaSP, SoLuong AS 'TonKho_BiTru5Chiec' FROM TON_KHO WHERE MaCuaHang = @CH_ID AND MaSP = 'IP15';

PRINT N'---> 2. KHÁCH BOOM HÀNG / HỦY ĐƠN (HOÀN LẠI KHO):';
UPDATE DON_HANG SET TrangThaiDonHang = N'Đã hủy' WHERE MaDH = @DH_HUY;
-- KỲ VỌNG: Kho được cộng trả lại 5 chiếc, về lại 99
SELECT MaSP, SoLuong AS 'TonKho_DuocHoanLai' FROM TON_KHO WHERE MaCuaHang = @CH_ID AND MaSP = 'IP15';
GO