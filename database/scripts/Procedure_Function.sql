USE BTL;
GO

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
GO

/* FUNCTION tính tổng số lượng bán của sản phẩm */
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
GO