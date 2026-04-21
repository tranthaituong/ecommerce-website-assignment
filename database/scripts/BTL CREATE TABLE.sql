CREATE DATABASE BTL
ON
(   NAME = 'BTL_data',
    FILENAME = 'C:\Users\PC\Desktop\DB\BTL_data.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB)
LOG ON
(   NAME = 'BTL_log',
    FILENAME = 'C:\Users\PC\Desktop\DB\BTL_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB);

USE BTL;

------ for drop
DROP TABLE PHIEU_VOUCHER;
DROP TABLE VOUCHER;
DROP TABLE DANH_GIA;
DROP TABLE THANH_TOAN;
DROP TABLE CHI_TIET_DON_HANG;
DROP TABLE DON_HANG;
DROP TABLE THONG_TIN_GIO_HANG;
DROP TABLE TON_KHO;
DROP TABLE THOI_TRANG;
DROP TABLE PHIEU_BAO_HANH;
DROP TABLE DIEN_TU;
DROP TABLE BIEN_THE_SAN_PHAM;
DROP TABLE SAN_PHAM;
DROP TABLE CA_LAM_VIEC;
DROP TABLE LAM_VIEC;
DROP TABLE CUA_HANG;
DROP TABLE DIA_CHI_KH;
DROP TABLE NHAN_VIEN;
DROP TABLE KHACH_HANG;
DROP TABLE TAI_KHOAN;

------
CREATE TABLE TAI_KHOAN (
    TenDangNhap VARCHAR(50) PRIMARY KEY,
    MatKhau VARBINARY(256) NOT NULL, --mật khẩu được lưu dạng hash
    NgayTao DATE,
    SDT CHAR(10) NOT NULL CONSTRAINT ct_sdt 
                             CHECK(SDT LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Email VARCHAR(50) NOT NULL CONSTRAINT ct_email
                               CHECK(Email LIKE '_%@gmail.com'), 
    VaiTro VARCHAR(20)
);

CREATE TABLE KHACH_HANG(
    KhachHangID INT IDENTITY(100,1) PRIMARY KEY,
    HoTen NVARCHAR(50) NOT NULL,
    DiemTichLuy INT DEFAULT 0,
    TenDangNhap VARCHAR(50) NOT NULL,

    FOREIGN KEY (TenDangNhap)
        REFERENCES TAI_KHOAN(TenDangNhap)
        --DELETE MAC DINH RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE NHAN_VIEN(
    MaNhanVien INT IDENTITY(1,1) PRIMARY KEY,
    CCCD CHAR(12) NOT NULL CONSTRAINT ct_cccd CHECK(LEN(CCCD) = 12),
    Luong INT DEFAULT 0 CONSTRAINT ct_luong CHECK(Luong >= 0),
    TenDangNhap VARCHAR(50) NOT NULL,

    FOREIGN KEY (TenDangNhap)
        REFERENCES TAI_KHOAN(TenDangNhap)
        --DELETE MAC DINH RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE DIA_CHI_KH(
    MaDiaChi INT NOT NULL,
    KhachHangID INT NOT NULL,

    SoNha NVARCHAR(5) NOT NULL,
    Huyen NVARCHAR(15) NOT NULL,
    Tinh NVARCHAR(15) NOT NULL,

    SDT_Nhan CHAR(10) NOT NULL 
        CONSTRAINT ct_sdtnhan 
        CHECK(SDT_Nhan LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),

    MacDinh BIT DEFAULT 0,

    PRIMARY KEY (MaDiaChi, KhachHangID),

    FOREIGN KEY (KhachHangID)
        REFERENCES KHACH_HANG(KhachHangID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

--INSERT INTO DIA_CHI_KH
--(KhachHangID, MaDiaChi, SoNha, Huyen, Tinh, SDT_Nhan)
--VALUES
--(@KHID,
-- (SELECT ISNULL(MAX(MaDiaChi),0)+1 
--  FROM DIA_CHI_KH 
--  WHERE KhachHangID = @KHID),
-- @SoNha, @Huyen, @Tinh, @SDT);

CREATE TABLE CUA_HANG(
    MaCuaHang INT IDENTITY(1000,1) PRIMARY KEY,
    SDT CHAR(10) NOT NULL
        CONSTRAINT ct_sdtcuahang
        CHECK(SDT LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    SoNha NVARCHAR(5) NOT NULL,
    Huyen NVARCHAR(15) NOT NULL,
    Tinh NVARCHAR(15) NOT NULL
);


CREATE TABLE LAM_VIEC(
    MaCuaHang INT NOT NULL,
    MaNhanVien INT NOT NULL,

    PRIMARY KEY(MaCuaHang, MaNhanVien),

    FOREIGN KEY(MaCuaHang)
            REFERENCES CUA_HANG(MaCuaHang)
            ON DELETE CASCADE,
    
    FOREIGN KEY(MaNhanVien)
            REFERENCES NHAN_VIEN(MaNhanVien)
            ON DELETE CASCADE
);

CREATE TABLE CA_LAM_VIEC(
    MaCuaHang INT NOT NULL,
    MaNhanVien INT NOT NULL,
    NgayLam DATE NOT NULL DEFAULT GETDATE(),
    CaLamViec TIME NOT NULL,
    KetThuc   TIME NOT NULL,

    PRIMARY KEY(MaCuaHang, MaNhanVien, NgayLam, CaLamViec),

    FOREIGN KEY(MaCuaHang, MaNhanVien)
        REFERENCES LAM_VIEC(MaCuaHang, MaNhanVien)
        ON DELETE CASCADE,

    CHECK(KetThuc > CaLamViec)
);

CREATE TABLE SAN_PHAM(
    MaSP NVARCHAR(50) PRIMARY KEY,
    TenSP NVARCHAR(50) NOT NULL,
    GiaSP INT DEFAULT 0
              CONSTRAINT ct_giasp
              CHECK(GiaSP >= 0),
    HangSanXuat NVARCHAR(50),
    DoiTra BIT DEFAULT 0
);

CREATE TABLE BIEN_THE_SAN_PHAM(
    MaSP NVARCHAR(50) NOT NULL,
    MaBT NVARCHAR(50) NOT NULL,
    CauHinh NVARCHAR(50),
    MauSac NVARCHAR(20),
    KichCo VARCHAR(3),

    PRIMARY KEY(MaSP, MaBT),
    FOREIGN KEY(MaSP)
            REFERENCES SAN_PHAM(MaSP)
);

CREATE TABLE DIEN_TU(
    MaSp NVARCHAR(50) PRIMARY KEY,
    ThongSoKyThuat NVARCHAR(100),
    HeDieuHanh NVARCHAR(50),

    FOREIGN KEY(MaSP)
            REFERENCES SAN_PHAM(MaSP)
            ON DELETE CASCADE
);

CREATE TABLE PHIEU_BAO_HANH(
    SoPhieu INT NOT NULL,
    MaSp NVARCHAR(50) NOT NULL, 
    NgayKichHoat DATE NOT NULL,
    NgayKetThuc  DATE NOT NULL,
    TinhTrang    BIT DEFAULT 0,

    PRIMARY KEY(SoPhieu, MaSP),
    FOREIGN KEY(MaSP)
            REFERENCES DIEN_TU(MaSP)
            ON DELETE CASCADE,

    CHECK(NgayKichHoat < NgayKetThuc)
);

CREATE TABLE THOI_TRANG(
    MaSP NVARCHAR(50) PRIMARY KEY,
    ChatLieu NVARCHAR(50),
    GioiTinh NVARCHAR(10) 
             DEFAULT N'Unisex'
             CONSTRAINT ct_gioitinh
             CHECK(GioiTinh = N'Nam' OR GioiTinh = N'Nữ' OR GioiTinh = N'Unisex')

    FOREIGN KEY(MaSP)
            REFERENCES SAN_PHAM(MaSP)
            ON DELETE CASCADE
);

CREATE TABLE TON_KHO(
     MaCuaHang INT NOT NULL,
     MaSP NVARCHAR(50) NOT NULL,
     MaBT NVARCHAR(50) NOT NULL,
     SoLuong INT DEFAULT 0 
                 CONSTRAINT ct_sl
                 CHECK(SoLuong >= 0),

    PRIMARY KEY(MaCuaHang, MaSP, MaBT),
    FOREIGN KEY(MaSP, MaBT)
            REFERENCES BIEN_THE_SAN_PHAM(MaSP, MaBT),

    FOREIGN KEY(MaCuaHang)
            REFERENCES CUA_HANG(MaCuaHang)
);


CREATE TABLE THONG_TIN_GIO_HANG(
    KhachHangID INT NOT NULL,
    MaSP NVARCHAR(50) NOT NULL,
    MaBT NVARCHAR(50) NOT NULL,
    SoLuong INT NOT NULL
                CONSTRAINT ct_slTamthoi
                CHECK(SoLuong >= 0),
    NgayThem DATE,

    PRIMARY KEY(KhachHangID, MaSP, MaBT),
    FOREIGN KEY(MaSP, MaBT)
            REFERENCES BIEN_THE_SAN_PHAM(MaSP, MaBT),
    FOREIGN KEY(KhachHangID)
            REFERENCES KHACH_HANG(KhachHangID)
);

CREATE TABLE DON_HANG( 
    MaDH INT IDENTITY(1,1) PRIMARY KEY, --- THEM TIEN SHIP
    KhachHangID INT NOT NULL,
    MaDiaChi INT NOT NULL,
    MaNhanVien INT NOT NULL,
    MaCuaHang INT NOT NULL,
    NgayDat DATE,
    NgayNhanDuKien DATE,
    NgayNhanThucTe DATE,
    TongTien INT NOT NULL DEFAULT 0,        
    TrangThaiDonHang NVARCHAR(30) NOT NULL DEFAULT N'Chờ xử lý', ---CHECK....
    FOREIGN KEY(MaDiaChi, KhachHangID)
            REFERENCES DIA_CHI_KH(MaDiaChi, KhachHangID),
    FOREIGN KEY(MaCuaHang, MaNhanVien)
            REFERENCES LAM_VIEC(MaCuaHang, MaNhanVien),

    CHECK(NgayNhanDuKien >= NgayDat)
);

CREATE TABLE CHI_TIET_DON_HANG(
    MaDH INT NOT NULL,
    MaSP NVARCHAR(50) NOT NULL,
    MaBT NVARCHAR(50) NOT NULL,
    SoLuong INT NOT NULL
                CONSTRAINT ct_slbt
                CHECK(SoLuong >= 0),
    GiaMotSP INT NOT NULL
            CONSTRAINT ct_Gia
            CHECK(GiaMotSP >= 0),
    ThanhTien INT NOT NULL DEFAULT 0,
    TrangThaiDanhGia BIT DEFAULT 0,
    TrangThaiDoiTra  BIT DEFAULT 0,

    PRIMARY KEY(MaDH, MaSP, MaBT),

    FOREIGN KEY(MaDH)
            REFERENCES DON_HANG(MaDH),
    
    FOREIGN KEY(MaSP, MaBT)
            REFERENCES BIEN_THE_SAN_PHAM(MaSP, MaBT)
);

CREATE TABLE THANH_TOAN(
    MaDH INT NOT NULL,
    MaThanhToan INT IDENTITY(1,1) NOT NULL,
    PhuongThucThanhToan NVARCHAR(20) NOT NULL,
    TrangThai NVARCHAR(20) NOT NULL,

    PRIMARY KEY(MaDH, MaThanhToan),
    FOREIGN KEY(MaDH)
            REFERENCES DON_HANG(MaDH)
);

CREATE TABLE DANH_GIA(
    MaDH INT NOT NULL,
    MaSP NVARCHAR(50) NOT NULL,
    MaBT NVARCHAR(50) NOT NULL,
    SoSao SMALLINT DEFAULT 5
                   CONSTRAINT ct_sosao
                   CHECK(SoSao >= 0 AND SoSao <= 5),
    NoiDung NVARCHAR(50),
    NgayDanhGia DATE,

    PRIMARY KEY(MaDH, MaSP, MaBT),

    FOREIGN KEY(MaDH, MaSP, MaBT)
            REFERENCES CHI_TIET_DON_HANG(MaDH, MaSP, MaBT)
);

CREATE TABLE VOUCHER(
    MaVoucher CHAR(10) 
              PRIMARY KEY
              CONSTRAINT ct_voucherValid
              CHECK(LEN(MaVoucher) = 10),

    Loai      NVARCHAR(30) NOT NULL
              DEFAULT N'CHO TỔNG TIỀN'
              CONSTRAINT ct_loai
              CHECK(Loai = N'CHO TỔNG TIỀN' OR Loai = N'CHO VẬN CHUYỂN'),

    GiaDonToiThieu INT 
                   DEFAULT 0
                   CONSTRAINT ct_min
                   CHECK(GiaDonToiThieu >= 0),

    PhanTramGiamGia DECIMAL(5,2) NOT NULL
                    CONSTRAINT ct_valid
                    CHECK(PhanTramGiamGia BETWEEN 0 AND 100),

    NgayHetHan DATE NOT NULL
               DEFAULT (DATEADD(MONTH, 3, GETDATE()))
);

CREATE TABLE PHIEU_VOUCHER(
    MaVoucher CHAR(10) NOT NULL,
    MaDH INT NOT NULL,
    KhachHangID INT NOT NULL,

    PRIMARY KEY(MaDH, MaVoucher),
    FOREIGN KEY(MaDH)
            REFERENCES DON_HANG(MaDH),
    FOREIGN KEY(MaVoucher)
            REFERENCES VOUCHER(MaVoucher),
);

--- CREATE INDEX cho cac FK lon
--TON_KHO
CREATE INDEX IX_TONKHO_MaSP_MaBT
ON TON_KHO(MaSP, MaBT);
--CHI_TIET_DOON_HANG
CREATE INDEX IX_CTDH_MaSP_MaBT
ON CHI_TIET_DON_HANG(MaSP, MaBT);
--DON_HANG
CREATE INDEX IX_DONHANG_KhachHang
ON DON_HANG(KhachHangID);
--DANH_GIA
CREATE INDEX IX_DANHGIA_MaDH
ON DANH_GIA(MaDH);

-- TO CLEAR DATA
TRUNCATE TABLE TAI_KHOAN;
TRUNCATE TABLE KHACH_HANG;
TRUNCATE TABLE NHAN_VIEN;
TRUNCATE TABLE DIA_CHI_KH;
TRUNCATE TABLE CUA_HANG;
TRUNCATE TABLE LAM_VIEC;
TRUNCATE TABLE CA_LAM_VIEC;
TRUNCATE TABLE SAN_PHAM;
TRUNCATE TABLE BIEN_THE_SAN_PHAM;
TRUNCATE TABLE DIEN_TU;
TRUNCATE TABLE PHIEU_BAO_HANH;
TRUNCATE TABLE THOI_TRANG;
TRUNCATE TABLE TON_KHO;
TRUNCATE TABLE THONG_TIN_GIO_HANG;
TRUNCATE TABLE DON_HANG;
TRUNCATE TABLE CHI_TIET_DON_HANG;
TRUNCATE TABLE THANH_TOAN;
TRUNCATE TABLE DANH_GIA;
TRUNCATE TABLE VOUCHER;
TRUNCATE TABLE PHIEU_VOUCHER;

-- 1. BẢNG TÀI KHOẢN ( 5 cho KH, 5 cho NV)
INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, NgayTao, SDT, Email, VaiTro)
VALUES 
('khachhang01', CAST('123456' AS VARBINARY(256)), '2026-01-10', '0901111111', 'kh01@gmail.com', 'KhachHang'),
('khachhang02', CAST('123456' AS VARBINARY(256)), '2026-02-15', '0902222222', 'kh02@gmail.com', 'KhachHang'),
('khachhang03', CAST('123456' AS VARBINARY(256)), '2026-03-20', '0903333333', 'kh03@gmail.com', 'KhachHang'),
('khachhang04', CAST('123456' AS VARBINARY(256)), '2026-04-18', '0904444444', 'kh04@gmail.com', 'KhachHang'),
('khachhang05', CAST('123456' AS VARBINARY(256)), '2026-03-30', '0905555555', 'kh05@gmail.com', 'KhachHang'),
('nhanvien01', CAST('admin1' AS VARBINARY(256)), '2026-01-01', '0911111111', 'nv01@gmail.com', 'NhanVien'),
('nhanvien02', CAST('admin2' AS VARBINARY(256)), '2026-01-02', '0912222222', 'nv02@gmail.com', 'NhanVien'),
('nhanvien03', CAST('admin3' AS VARBINARY(256)), '2026-01-02', '0913333333', 'nv03@gmail.com', 'NhanVien'),
('nhanvien04', CAST('admin4' AS VARBINARY(256)), '2026-01-03', '0914444444', 'nv04@gmail.com', 'NhanVien'),
('nhanvien05', CAST('admin5' AS VARBINARY(256)), '2026-01-05', '0915555555', 'nv05@gmail.com', 'NhanVien');

-- 2. BẢNG KHÁCH HÀNG (Sẽ tự động sinh ID từ 100)
INSERT INTO KHACH_HANG (HoTen, DiemTichLuy, TenDangNhap)
VALUES 
(N'Nguyễn Văn A', 100, 'khachhang01'),
(N'Trần Thị B', 250, 'khachhang02'),
(N'Lê Văn C', 50, 'khachhang03'),
(N'Phạm Thị D', 500, 'khachhang04'),
(N'Hoàng Văn E', 0, 'khachhang05');

-- 3. BẢNG NHÂN VIÊN (Sẽ tự động sinh ID từ 1)
INSERT INTO NHAN_VIEN (CCCD, Luong, TenDangNhap)
VALUES 
('079099000111', 15000000, 'nhanvien01'),
('079099000222', 12000000, 'nhanvien02'),
('079099000333', 13500000, 'nhanvien03'),
('079099000444', 11000000, 'nhanvien04'),
('079099000555', 20000000, 'nhanvien05');

-- 4. BẢNG ĐỊA CHỈ KHÁCH HÀNG

INSERT INTO DIA_CHI_KH (MaDiaChi, KhachHangID, SoNha, Huyen, Tinh, SDT_Nhan, MacDinh)
VALUES 
(1, 100, N'12A', N'Quận 1', N'TP.HCM', '0901111111', 1),
(1, 101, N'34B', N'Quận 3', N'TP.HCM', '0902222222', 1),
(1, 102, N'56C', N'Quận 10', N'TP.HCM', '0903333333', 1),
(1, 103, N'78D', N'Dĩ An', N'Bình Dương', '0904444444', 1),
(2, 103, N'99E', N'Thủ Đức', N'TP.HCM', '0904444444', 0), -- Khách hàng này có 2 địa chỉ
(1, 104, N'11F', N'Biên Hòa', N'Đồng Nai', '0905555555', 1);

-- 5. BẢNG CỬA HÀNG (Sẽ tự động sinh ID từ 1000)
INSERT INTO CUA_HANG (SDT, SoNha, Huyen, Tinh)
VALUES 
('0283333333', N'111', N'Quận 1', N'TP.HCM'),
('0284444444', N'222', N'Quận 5', N'TP.HCM'),
('0285555555', N'333', N'Bình Thạnh', N'TP.HCM'),
('0274666666', N'444', N'Dĩ An', N'Bình Dương'),
('0251777777', N'555', N'Biên Hòa', N'Đồng Nai');

-- 6. BẢNG LÀM VIỆC (Phân công nhân viên vào cửa hàng)
INSERT INTO LAM_VIEC (MaCuaHang, MaNhanVien)
VALUES 
(1000, 1),
(1001, 2),
(1002, 3),
(1003, 4),
(1004, 5);

-- 7. BẢNG CA LÀM VIỆC
INSERT INTO CA_LAM_VIEC (MaCuaHang, MaNhanVien, NgayLam, CaLamViec, KetThuc)
VALUES 
(1000, 1, '2026-04-01', '08:00', '16:00'),
(1001, 2, '2026-04-01', '14:00', '22:00'),
(1002, 3, '2026-04-01', '08:00', '16:00'),
(1003, 4, '2026-04-02', '08:00', '16:00'),
(1004, 5, '2026-04-02', '14:00', '22:00');

-- 8. BẢNG SẢN PHẨM (Gồm cả điện tử và thời trang)
INSERT INTO SAN_PHAM (MaSP, TenSP, GiaSP, HangSanXuat, DoiTra)
VALUES 
('SP01', N'Điện thoại iPhone 17', 25000000, N'Apple', 1),
('SP02', N'Laptop ThinkPad T14', 30000000, N'Lenovo', 1),
('SP03', N'Tai nghe AirPods Pro', 5000000, N'Apple', 1),
('SP04', N'Áo thun Polo', 150000, N'Coolmate', 0),
('SP05', N'Quần Jeans Nam', 500000, N'Levis', 0);

-- 9. BẢNG BIẾN THỂ SẢN PHẨM
INSERT INTO BIEN_THE_SAN_PHAM (MaSP, MaBT, CauHinh, MauSac, KichCo)
VALUES 
('SP01', 'BT01', N'128GB', N'Đen', NULL),
('SP01', 'BT02', N'256GB', N'Hồng', NULL),
('SP02', 'BT01', N'i7-16GB-512GB', N'Đen', NULL),
('SP03', 'BT01', NULL, N'Đen', NULL),
('SP04', 'BT01', NULL, N'Trắng', 'M'),
('SP05', 'BT01', NULL, N'Xanh', 'L');

-- 10. BẢNG ĐIỆN TỬ
INSERT INTO DIEN_TU (MaSp, ThongSoKyThuat, HeDieuHanh)
VALUES 
('SP01', N'Màn hình 6.1 inch, Chip A18', N'iOS'),
('SP02', N'Màn hình 14 inch, Chip Intel i7', N'Windows 11'),
('SP03', N'Chống ồn chủ động ANC', N'Không có');

-- 11. BẢNG PHIẾU BẢO HÀNH
INSERT INTO PHIEU_BAO_HANH (SoPhieu, MaSp, NgayKichHoat, NgayKetThuc, TinhTrang)
VALUES 
(1, 'SP01', '2026-01-01', '2027-01-01', 1),
(2, 'SP02', '2026-02-15', '2027-02-15', 1),
(3, 'SP03', '2026-03-10', '2027-03-10', 1),
(4, 'SP01', '2026-03-20', '2027-05-20', 0),
(5, 'SP02', '2026-04-08', '2027-08-08', 0);

-- 12. BẢNG THỜI TRANG
INSERT INTO THOI_TRANG (MaSP, ChatLieu, GioiTinh)
VALUES 
('SP04', N'Cotton 100%', N'Nam'),
('SP05', N'Denim', N'Unisex');

-- 13. BẢNG TỒN KHO
INSERT INTO TON_KHO (MaCuaHang, MaSP, MaBT, SoLuong)
VALUES 
(1000, 'SP01', 'BT01', 50),
(1000, 'SP01', 'BT02', 50),
(1000, 'SP02', 'BT01', 20),
(1000, 'SP03', 'BT01', 30),
(1000, 'SP04', 'BT01', 25),
(1000, 'SP05', 'BT01', 20),
(1001, 'SP01', 'BT01', 10),
(1001, 'SP01', 'BT02', 50),
(1001, 'SP02', 'BT01', 20),
(1001, 'SP04', 'BT01', 100),
(1001, 'SP05', 'BT01', 150),
(1002, 'SP01', 'BT01', 80),
(1002, 'SP02', 'BT01', 30),
(1002, 'SP03', 'BT01', 60),
(1003, 'SP01', 'BT02', 30),
(1003, 'SP03', 'BT01', 20),
(1003, 'SP04', 'BT01', 50),
(1004, 'SP03', 'BT01', 20),
(1004, 'SP01', 'BT02', 50),
(1004, 'SP01', 'BT01', 20),
(1004, 'SP02', 'BT01', 20);

-- 14. BẢNG THÔNG TIN GIỎ HÀNG
INSERT INTO THONG_TIN_GIO_HANG (KhachHangID, MaSP, MaBT, SoLuong, NgayThem)
VALUES 
(100, 'SP01', 'BT01', 1, '2026-04-05'),
(100, 'SP02', 'BT01', 1, '2026-04-05'),
(101, 'SP04', 'BT01', 2, '2026-04-06'),
(102, 'SP05', 'BT01', 1, '2026-04-07'),
(103, 'SP01', 'BT01', 1, '2026-04-08'),
(103, 'SP04', 'BT01', 1, '2026-04-08'),
(103, 'SP05', 'BT01', 1, '2026-04-08'),
(104, 'SP01', 'BT01', 1, '2026-04-09'),
(104, 'SP01', 'BT02', 1, '2026-04-09');

-- 15. BẢNG ĐƠN HÀNG (Sinh ID từ 1)
INSERT INTO DON_HANG (KhachHangID, MaDiaChi, MaNhanVien, MaCuaHang, NgayDat, NgayNhanDuKien, NgayNhanThucTe, TongTien, TrangThaiDonHang)
VALUES 
(100, 1, 1, 1000, '2026-04-15', '2026-04-18', '2026-04-18', 25000000, N'Hoàn thành'),
(101, 1, 2, 1001, '2026-04-15', '2026-04-22', NULL, 700000, N'Đang giao hàng'),
(102, 1, 3, 1002, '2026-04-16', '2026-04-18', '2026-04-18', 500000, N'Hoàn thành'),
(103, 1, 4, 1003, '2026-04-16', '2026-04-21', NULL, 30000000, N'Chờ xử lý'),
(104, 1, 5, 1004, '2026-04-17', '2026-04-27', NULL, 25000000, N'Chờ xử lý');

-- 16. BẢNG CHI TIẾT ĐƠN HÀNG
INSERT INTO CHI_TIET_DON_HANG (MaDH, MaSP, MaBT, SoLuong, GiaMotSP, ThanhTien, TrangThaiDanhGia, TrangThaiDoiTra)
VALUES 
(1, 'SP01', 'BT01', 1, 25000000, 25000000, 1, 0),
(2, 'SP04', 'BT01', 2, 350000, 700000, 1, 0),
(3, 'SP05', 'BT01', 1, 500000, 500000, 0, 0),
(4, 'SP02', 'BT01', 1, 30000000, 30000000, 1, 1),
(5, 'SP01', 'BT02', 1, 25000000, 25000000, 1, 1);

-- 17. BẢNG THANH TOÁN

INSERT INTO THANH_TOAN (MaDH, PhuongThucThanhToan, TrangThai)
VALUES 
(1, N'COD', N'Đã thanh toán'),
(2, N'Online', N'Đã thanh toán'),
(3, N'Online', N'Đã thanh toán'),
(4, N'COD',  N'Chưa thanh toán'),
(5, N'COD', N'Chưa thanh toán');

-- 18. BẢNG ĐÁNH GIÁ
INSERT INTO DANH_GIA (MaDH, MaSP, MaBT, SoSao, NoiDung, NgayDanhGia)
VALUES 
(3, 'SP05', 'BT01', 5, N'Chất vải xịn sò', '2026-04-18');

-- 19. BẢNG VOUCHER (Đảm bảo mã Voucher đúng 10 ký tự)
INSERT INTO VOUCHER (MaVoucher, Loai, GiaDonToiThieu, PhanTramGiamGia, NgayHetHan)
VALUES 
('GIAM50K001', N'CHO TỔNG TIỀN', 500000, 10.00, '2026-12-31'),
('FREESHIP01', N'CHO VẬN CHUYỂN', 300000, 100.00,'2026-12-31'),
('SALE100K01', N'CHO TỔNG TIỀN', 1000000, 5.00, '2026-12-31'),
('MEGAXMAS01', N'CHO TỔNG TIỀN', 20000000, 2.00, '2026-12-31'),
('SHIPFREE02', N'CHO VẬN CHUYỂN', 0, 50.00, '2026-12-31');

-- 20. BẢNG PHIẾU VOUCHER (Áp dụng voucher cho các đơn hàng)
INSERT INTO PHIEU_VOUCHER (MaVoucher, MaDH, KhachHangID)
VALUES 
('MEGAXMAS01', 1, 100),
('GIAM50K001', 2, 101),
('FREESHIP01', 3, 102),
('SALE100K01', 4, 103),
('SHIPFREE02', 5, 104);

---DROP TRIGGRER
DROP TRIGGER IF EXISTS TRG_TinhThanhTien;
DROP TRIGGER IF EXISTS TRG_CapNhatTongTien;
DROP TRIGGER IF EXISTS TRG_CapNhatDiem_TonKho;
DROP TRIGGER IF EXISTS TRG_KiemTraDanhGia;
---TRIGGER 

-- 1.Trigger tính ThanhTien
CREATE TRIGGER TRG_TinhThanhTien
ON CHI_TIET_DON_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    -- Chỉ chạy khi cột SoLuong hoặc GiaMotSP có sự thay đổi
    UPDATE ct
    SET ct.ThanhTien = i.SoLuong * i.GiaMotSP
    FROM CHI_TIET_DON_HANG ct
    JOIN inserted i 
        ON ct.MaDH = i.MaDH 
        AND ct.MaSP = i.MaSP 
        AND ct.MaBT = i.MaBT;
END;

GO

--2.Trigger tính TongTien
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

--3.Trigger cập nhật DiemTichLuy + SoLuong tồn kho
CREATE TRIGGER TRG_CapNhatDiem_TonKho
ON DON_HANG
AFTER UPDATE
AS
BEGIN
    -- Chỉ thực thi khi cột TrangThaiDonHang được cập nhật
    IF UPDATE(TrangThaiDonHang)
    BEGIN
        -- CỘNG ĐIỂM TÍCH LŨY CHO KHÁCH HÀNG (Tỷ lệ: Tổng tiền / 1000)
        UPDATE kh
        SET kh.DiemTichLuy = kh.DiemTichLuy + (i.TongTien / 1000)
        FROM KHACH_HANG kh
        JOIN inserted i ON kh.KhachHangID = i.KhachHangID
        JOIN deleted d ON i.MaDH = d.MaDH
        -- Điều kiện: Trạng thái mới là Hoàn thành, trạng thái cũ khác Hoàn thành
        WHERE i.TrangThaiDonHang = N'Hoàn thành' AND d.TrangThaiDonHang <> N'Hoàn thành';

        -- TRỪ TỒN KHO TẠI CỬA HÀNG GIAO ĐƠN
        UPDATE tk
        SET tk.SoLuong = tk.SoLuong - ct.SoLuong
        FROM TON_KHO tk
        JOIN inserted i ON tk.MaCuaHang = i.MaCuaHang
        JOIN deleted d ON i.MaDH = d.MaDH
        JOIN CHI_TIET_DON_HANG ct ON i.MaDH = ct.MaDH AND tk.MaSP = ct.MaSP AND tk.MaBT = ct.MaBT
        WHERE i.TrangThaiDonHang = N'Hoàn thành' AND d.TrangThaiDonHang <> N'Hoàn thành';
    END
END;

/* 4 Trigegr rang buoc danh gia */
CREATE TRIGGER TRG_KiemTraDanhGia
ON DANH_GIA
FOR INSERT
AS
BEGIN
    DECLARE @MaDH INT, @MaSP NVARCHAR(50), @MaBT NVARCHAR(50);
    DECLARE @TrangThaiDH NVARCHAR(30), @NgayNhan DATE, @TrangThaiDG BIT;

    -- Lay thong tin
    SELECT @MaDH = i.MaDH, @MaSP = i.MaSP, @MaBT = i.MaBT,
           @TrangThaiDH = dh.TrangThaiDonHang, 
           @NgayNhan = dh.NgayNhanThucTe,
           @TrangThaiDG = ctdh.TrangThaiDanhGia
    FROM inserted i
    JOIN CHI_TIET_DON_HANG ctdh ON i.MaDH = ctdh.MaDH 
	AND i.MaSP = ctdh.MaSP 
	AND i.MaBT = ctdh.MaBT
    JOIN DON_HANG dh ON i.MaDH = dh.MaDH;

    -- Ktra don hang da hoan thanh
    IF (@TrangThaiDH <> N'Hoàn thành')
    BEGIN
        RAISERROR(N'Lỗi: Bạn chỉ có thể đánh giá khi đơn hàng đã ở trạng thái "Hoàn thành"!', 16, 1);
        ROLLBACK;
        RETURN;
    END

    -- Ktra 30 day nhan thuc te
    IF (DATEDIFF(DAY, @NgayNhan, GETDATE()) > 30)
    BEGIN
        RAISERROR(N'Lỗi: Đã quá hạn 30 ngày để thực hiện đánh giá cho đơn hàng này!', 16, 1);
        ROLLBACK;
        RETURN;
    END

    -- Ktra danh gia (TrangThaiDanhGia = 0 ko dang gia nua)
    IF (@TrangThaiDG = 0)
    BEGIN
        RAISERROR(N'Lỗi: Bạn đã đánh giá sản phẩm này', 16, 1);
        ROLLBACK;
        RETURN;
    END
END;

-- DROP PROCEDURE
DROP PROCEDURE sp_ThemSanPham;
DROP PROCEDURE sp_SuaSanPham;
DROP PROCEDURE sp_XoaSanPham;

---PROCEDURE ADD/UPDATE/DELETE SAN_PHAM
-- PROCEDURE ThemSP
CREATE PROCEDURE sp_ThemSanPham
    @MaSP NVARCHAR(50),
    @TenSP NVARCHAR(50),
    @GiaSP INT,
    @HangSanXuat NVARCHAR(50),
    @DoiTra BIT
AS
BEGIN
    SET NOCOUNT ON;

       IF EXISTS (SELECT 1 FROM SAN_PHAM WHERE MaSP = @MaSP)
    BEGIN
        RAISERROR(N'Lỗi: Mã sản phẩm [%s] đã tồn tại.', 16, 1, @MaSP);
        RETURN;
    END

       IF (@TenSP IS NULL OR TRIM(@TenSP) = '')
    BEGIN
        RAISERROR(N'Lỗi: Tên sản phẩm không được để trống!', 16, 1);
        RETURN;
    END

    IF (@GiaSP < 0)
    BEGIN
        RAISERROR(N'Lỗi: Giá sản phẩm phải lớn hơn hoặc bằng 0', 16, 1);
        RETURN;
    END

     BEGIN TRY
        INSERT INTO SAN_PHAM (MaSP, TenSP, GiaSP, HangSanXuat, DoiTra)
        VALUES (@MaSP, @TenSP, @GiaSP, @HangSanXuat, @DoiTra);
        
        PRINT N'Thành công: Đã thêm sản phẩm mới.';
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(N'Lỗi hệ thống: %s', 16, 1, @Err);
    END CATCH
END;

/* PROCEDURE cập nhật sản phẩm */
CREATE PROCEDURE sp_SuaSanPham
    @MaSP NVARCHAR(50),
    @TenSP NVARCHAR(50),
    @GiaSP INT,
    @HangSanXuat NVARCHAR(50),
    @DoiTra BIT
AS
BEGIN
    -- Kiểm tra sản phẩm có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM SAN_PHAM WHERE MaSP = @MaSP)
    BEGIN
        RAISERROR(N'Lỗi: Sản phẩm với mã %s không tồn tại!', 16, 1, @MaSP);
        RETURN;
    END

    -- Kiểm tra tên sản phẩm không để trống
    IF (@TenSP IS NULL OR TRIM(@TenSP) = '')
    BEGIN
        RAISERROR(N'Lỗi: Tên sản phẩm không được để trống!', 16, 1);
        RETURN;
    END

    -- Kiểm tra giá sản phẩm hợp lệ (>= 0)
    IF @GiaSP < 0
    BEGIN
        RAISERROR(N'Lỗi: Giá sản phẩm phải lớn hơn hoặc bằng 0!', 16, 1);
        RETURN;
    END

    -- Cập nhật sản phẩm
    UPDATE SAN_PHAM
    SET TenSP = @TenSP,
        GiaSP = @GiaSP,
        HangSanXuat = @HangSanXuat,
        DoiTra = @DoiTra
    WHERE MaSP = @MaSP;

    PRINT N'Đã cập nhật sản phẩm thành công.';
END;

/* ProceduRe Xóa */
CREATE PROCEDURE sp_XoaSanPham
    @MaSP NVARCHAR(50)
AS
BEGIN
    --Kiểm tra mã sản phảm có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM SAN_PHAM WHERE MaSP = @MaSP )
    BEGIN
        RAISERROR(N'Lỗi: mã sản phẩm không tồn tại', 16, 1);
        RETURN;
    END
    --Kiểm tra mã sản phảm có đang trong CHI_TIET_DON_HANG nào không
    IF EXISTS (SELECT 1 FROM CHI_TIET_DON_HANG WHERE MaSP = @MaSP)
    BEGIN
        RAISERROR(N'Lỗi: Không thể xóa sản phẩm này vì nó đã tồn tại trong lịch sử đơn hàng!', 16, 1);
        RETURN;
    END

    -- Xoa sp
    DELETE FROM SAN_PHAM 
    WHERE MaSP = @MaSP;

    PRINT N'Đã xóa sản phẩm thành công.';
END;

--DROP PROCEDURE
DROP PROCEDURE sp_DanhSachDonHangTheoKhach;
DROP PROCEDURE sp_ThongKeDoanhThuCuaHang;
DROP PROCEDURE sp_ThongKeDanhSachSanPham;

---PROCEDURE TRUY VAN
-- Danh sách đơn hàng theo khách và khoảng ngày 
CREATE PROCEDURE sp_DanhSachDonHangTheoKhach
    @KhachHangID INT,
    @TuNgay DATE,
    @DenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (@TuNgay > @DenNgay)
    BEGIN
        RAISERROR(N'Lỗi: Ngày bắt đầu không được lớn hơn ngày kết thúc!', 16, 1);
        RETURN;
    END
    SELECT 
        dh.MaDH, 
        dh.NgayDat, 
        dh.TongTien, 
        dh.TrangThaiDonHang, 
        kh.HoTen, 
        dh.MaCuaHang
    FROM DON_HANG dh
    INNER JOIN KHACH_HANG kh ON dh.KhachHangID = kh.KhachHangID 
    WHERE dh.KhachHangID = @KhachHangID
      AND dh.NgayDat BETWEEN @TuNgay AND @DenNgay 
    ORDER BY dh.NgayDat DESC; 
END;

--2.Thống kê doanh thu theo cửa hàng 
CREATE PROCEDURE sp_ThongKeDoanhThuCuaHang
 		@TuNgay DATE,
 		@DenNgay DATE,
 		@DoanhThuToiThieu INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@TuNgay > @DenNgay)
    BEGIN
        RAISERROR(N'Lỗi: Ngày bắt đầu không được lớn hơn ngày kết thúc!', 16, 1);
        RETURN;
    END

    SELECT ch.MaCuaHang,
           COUNT(dh.MaDH) AS SoDonHang,
           SUM(dh.TongTien) AS TongDoanhThu
    FROM DON_HANG AS dh
    JOIN CUA_HANG AS ch ON dh.MaCuaHang = ch.MaCuaHang
    WHERE dh.NgayDat BETWEEN @TuNgay AND @DenNgay
        AND dh.TrangThaiDonHang = N'Hoàn thành'
    GROUP BY ch.MaCuaHang
    HAVING SUM(dh.TongTien) >= @DoanhThuToiThieu
    ORDER BY TongDoanhThu ASC;
END;

--3. Danh sách Sản Phẩm kèm Tổng số lượng tồn kho và Tổng số lượng đã bán,Tổng số lượng đang vạn chuyển
CREATE PROCEDURE sp_ThongKeDanhSachSanPham
       @TuKhoa NVARCHAR(50) = N'',
       @GiaMIN INT = 0,
       @GiaMAX INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sp.MaSP,
        sp.TenSP,
        sp.GiaSP,
        bt.MaBT,
        MAX(ISNULL(Kho.TongTonKho, 0)) AS SoLuongTonKho,
        SUM(ct.SoLuong) AS TongSoLuongDaBan,
        SUM(ct.ThanhTien) AS TongDoanhThu
    FROM SAN_PHAM AS sp
    JOIN BIEN_THE_SAN_PHAM AS bt 
        ON sp.MaSP = bt.MaSP
    JOIN CHI_TIET_DON_HANG AS ct
        ON bt.MaSP = ct.MaSP AND bt.MaBT = ct.MaBT
    LEFT JOIN (
        SELECT MaSP, MaBT, SUM(SoLuong) AS TongTonKho
        FROM TON_KHO
        GROUP BY MaSP, MaBT
    ) AS Kho ON bt.MaSP = Kho.MaSP AND bt.MaBT = Kho.MaBT
    WHERE
        ((sp.TenSP LIKE N'%' + @TuKhoa + N'%') OR (@TuKhoa = N'')) 
        AND (sp.GiaSP >= @GiaMIN)
        AND (@GiaMAX IS NULL OR sp.GiaSP <= @GiaMAX)
    GROUP BY sp.MaSP, sp.TenSP, sp.GiaSP, bt.MaBT
    -- Lọc các sản phẩm đã bán được HOẶC đang tồn kho quá 50 cái ( KO BAN DC HANG)
    HAVING SUM(ct.SoLuong) > 0 OR MAX(ISNULL(Kho.TongTonKho, 0)) > 50
    ORDER BY TongDoanhThu DESC;
END;

GO


--2 Function 
-- DROP FUNCTION
DROP FUNCTION fn_TongTienKhachHang;
DROP FUNCTION fn_TongSoLuongBanSanPham

--Function 1 — Tính tổng tiền khách hàng trong khoảng ngày
CREATE FUNCTION fn_TongTienKhachHang
(
    @KhachHangID INT,
    @TuNgay DATE,
    @DenNgay DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Tong INT = 0;
    DECLARE @TienDon INT;

    IF @TuNgay > @DenNgay
        RETURN -1;

    DECLARE cur CURSOR FOR
    SELECT TongTien
    FROM DON_HANG
    WHERE KhachHangID = @KhachHangID
      AND NgayDat BETWEEN @TuNgay AND @DenNgay
      AND TrangThaiDonHang = N'Hoàn thành';

    OPEN cur;
    FETCH NEXT FROM cur INTO @TienDon;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Tong = @Tong + @TienDon;
        FETCH NEXT FROM cur INTO @TienDon;
    END

    CLOSE cur;
    DEALLOCATE cur;

    RETURN @Tong;
END;


/* FUNCTION 2 - tính tổng số lượng bán của sản phẩm */
CREATE FUNCTION fn_TongSoLuongBanSanPham
(
    @MaSP NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @TongSoLuong INT = 0;
    DECLARE @SoLuong INT;

    -- Khai báo CURSOR để duyệt chi tiết đơn hàng
    DECLARE cur_ChiTiet CURSOR FOR
        SELECT SoLuong
        FROM CHI_TIET_DON_HANG
        WHERE MaSP = @MaSP;

    OPEN cur_ChiTiet;

    FETCH NEXT FROM cur_ChiTiet INTO @SoLuong;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TongSoLuong = @TongSoLuong + @SoLuong;
        FETCH NEXT FROM cur_ChiTiet INTO @SoLuong;
    END

    CLOSE cur_ChiTiet;
    DEALLOCATE cur_ChiTiet;

    RETURN @TongSoLuong;
END;


