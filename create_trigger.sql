-- PHẦN TRIGGER NGHIỆP VỤ

-- 1. Kiểm tra tồn kho và giá sản phẩm khi thêm chi tiết đơn hàng
CREATE OR REPLACE TRIGGER trg_kiemtra_ctdh
BEFORE INSERT OR UPDATE ON ChiTietDonHang
FOR EACH ROW
DECLARE
    v_ton NUMBER;
    v_gia_sp NUMBER;
BEGIN
    SELECT so_luong, gia INTO v_ton, v_gia_sp
    FROM SanPham
    WHERE ma_san_pham = :NEW.ma_san_pham
    FOR UPDATE;

    IF :NEW.so_luong > v_ton THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Số lượng đặt (' || :NEW.so_luong || ') vượt quá tồn kho (' || v_ton || ').');
    END IF;

    IF :NEW.don_gia <> v_gia_sp THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Giá đơn hàng (' || :NEW.don_gia || ') không khớp với giá sản phẩm (' || v_gia_sp || ').');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'Sản phẩm không tồn tại: ' || :NEW.ma_san_pham);
END;
/

-- 2. Cập nhật tồn kho khi đơn hàng được xác nhận
CREATE OR REPLACE TRIGGER trg_capnhat_tonkho_sau_xacnhan
AFTER UPDATE OF trang_thai ON DonHang
FOR EACH ROW
WHEN (NEW.trang_thai = 'DA_XAC_NHAN')
BEGIN
    UPDATE SanPham sp
    SET sp.so_luong = sp.so_luong - (
        SELECT NVL(SUM(ct.so_luong),0)
        FROM ChiTietDonHang ct
        WHERE ct.ma_san_pham = sp.ma_san_pham
          AND ct.ma_don_hang = :NEW.ma_don_hang
    )
    WHERE sp.ma_san_pham IN (
        SELECT ma_san_pham FROM ChiTietDonHang WHERE ma_don_hang = :NEW.ma_don_hang
    );
END;
/

-- 3. Tự động cập nhật trạng thái đơn hàng khi giao hàng xong
CREATE OR REPLACE TRIGGER trg_tudong_capnhat_trangthai_donhang
AFTER UPDATE OF trang_thai ON ThongTinVanChuyen
FOR EACH ROW
WHEN (NEW.trang_thai = 'DA_GIAO')
BEGIN
    UPDATE DonHang
    SET trang_thai = 'DA_GIAO'
    WHERE ma_don_hang = :NEW.ma_don_hang;
END;
/

-- 4. Ngăn không cho tồn kho âm
CREATE OR REPLACE TRIGGER trg_nga_tonkho_am
BEFORE UPDATE OF so_luong ON SanPham
FOR EACH ROW
BEGIN
    IF :NEW.so_luong < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Không được để số lượng tồn kho âm!');
    END IF;
END;
/

-- 5. Chỉ cho phép đánh giá sau khi đơn hàng giao thành công
-- Trigger kiểm tra quyền đánh giá sản phẩm
CREATE OR REPLACE TRIGGER trg_kiemtra_quyen_danhgia
BEFORE INSERT ON ThongTinDanhGia
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Kiểm tra xem sản phẩm có thuộc đơn hàng của tài khoản và đơn đã giao chưa
    SELECT COUNT(*) INTO v_count
    FROM ChiTietDonHang ct
    JOIN DonHang dh ON ct.ma_don_hang = dh.ma_don_hang
    WHERE ct.ma_san_pham = :NEW.ma_san_pham
      AND dh.ma_don_hang = :NEW.ma_don_hang
      AND dh.ma_tai_khoan = :NEW.ma_tai_khoan
      AND dh.trang_thai = 'DA_GIAO';

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Chỉ được đánh giá sản phẩm sau khi đơn hàng đã giao thành công!');
    END IF;
END;
/

--Commit;

-- DESC ThongTinDanhGia;
-- 6. Trigger đồng bộ trạng thái (Tài khoản → Cửa hàng → Sản phẩm)
CREATE OR REPLACE TRIGGER trg_capnhat_trang_thai
AFTER UPDATE OF trang_thai_tai_khoan ON TaiKhoan
FOR EACH ROW
WHEN (NEW.trang_thai_tai_khoan = 'NGUNG_HOAT_DONG')
BEGIN
    -- Cập nhật cửa hàng thuộc tài khoản ngừng hoạt động
    UPDATE CuaHang
    SET trang_thai_cua_hang = 'NGUNG_HOAT_DONG'
    WHERE ma_tai_khoan = :NEW.ma_tai_khoan;

    -- Cập nhật sản phẩm thuộc các cửa hàng đó thành ngừng bán
    UPDATE SanPham
    SET trang_thai_san_pham = 'NGUNG_BAN'
    WHERE ma_cua_hang IN (
        SELECT ma_cua_hang FROM CuaHang WHERE ma_tai_khoan = :NEW.ma_tai_khoan
    );
END;
/


--   7. TRigger ngày giao phải lớn hơn ngày đặt
CREATE OR REPLACE TRIGGER trg_check_ngay_giao
BEFORE INSERT OR UPDATE ON ThongTinVanChuyen
FOR EACH ROW
DECLARE
    v_ngay_dat DATE;
BEGIN
    SELECT ngay_dat INTO v_ngay_dat
    FROM DonHang
    WHERE ma_don_hang = :NEW.ma_don_hang;

    IF :NEW.ngay_giao_du_kien IS NOT NULL AND :NEW.ngay_giao_du_kien < v_ngay_dat THEN
        RAISE_APPLICATION_ERROR(-20001, 'Ngay giao du kien phai >= ngay dat');
    END IF;
END;
/


-- 8.  trigger kiểm tra ngày  sinh ở bảng người dùng
CREATE OR REPLACE TRIGGER trg_check_ngay_sinh
BEFORE INSERT OR UPDATE ON NguoiDung
FOR EACH ROW
BEGIN
    IF :NEW.ngay_sinh >= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'Ngay sinh phai nho hon ngay hien tai');
    END IF;
END;
/