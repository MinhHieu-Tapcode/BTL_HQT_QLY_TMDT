-- CƠ SỞ DỮ LIỆU: Qly_E_Commerce 


-- 1. Bảng Người Dùng
CREATE TABLE NguoiDung (
    ma_nguoi_dung NUMBER(10) PRIMARY KEY,
    ho_ten NVARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    sdt CHAR(10) UNIQUE,
    ngay_sinh DATE
);
-- 2. Bảng Tài Khoản

CREATE TABLE TaiKhoan (
    ma_tai_khoan NUMBER(10) PRIMARY KEY,
    ma_nguoi_dung NUMBER(10) NOT NULL,
    ten_tai_khoan VARCHAR2(50) UNIQUE NOT NULL,
    mat_khau VARCHAR2(255) NOT NULL,
    loai_tai_khoan VARCHAR2(10)
        CHECK (loai_tai_khoan IN ('USER','STORE','ADMIN')),
    trang_thai_tai_khoan VARCHAR2(20)
        DEFAULT 'HOAT_DONG'
        CHECK (trang_thai_tai_khoan IN ('HOAT_DONG', 'NGUNG_HOAT_DONG')),
    CONSTRAINT fk_taikhoan_nguoidung FOREIGN KEY (ma_nguoi_dung)
        REFERENCES NguoiDung(ma_nguoi_dung)
);

--
-- SELECT object_name, object_type
-- FROM user_objects
-- WHERE object_name = 'TAIKHOAN';

-- DROP TABLE TaiKhoan CASCADE CONSTRAINTS;

-- 3. Bảng Loại Cửa Hàng
CREATE TABLE LoaiCuaHang (
    ma_loai_cua_hang NUMBER(5) PRIMARY KEY,
    ten_loai NVARCHAR2(100) NOT NULL UNIQUE
);

-- 4. Bảng Cửa Hàng
CREATE TABLE CuaHang (
    ma_cua_hang NUMBER(10) PRIMARY KEY,
    ma_tai_khoan NUMBER(10) NOT NULL UNIQUE,
    ten_cua_hang NVARCHAR2(150) NOT NULL,
    dia_chi NVARCHAR2(255),
    ma_loai_cua_hang NUMBER(5) NOT NULL,
    trang_thai_cua_hang VARCHAR2(20)
        DEFAULT 'HOAT_DONG'
        CHECK (trang_thai_cua_hang IN ('HOAT_DONG', 'NGUNG_HOAT_DONG')),
    CONSTRAINT fk_cuahang_taikhoan FOREIGN KEY (ma_tai_khoan)
        REFERENCES TaiKhoan(ma_tai_khoan),
    CONSTRAINT fk_cuahang_loaicuahang FOREIGN KEY (ma_loai_cua_hang)
        REFERENCES LoaiCuaHang(ma_loai_cua_hang)
);

-- 5. Bảng Loại Sản Phẩm
CREATE TABLE LoaiSanPham (
    ma_loai_san_pham NUMBER(5) PRIMARY KEY,
    ten_loai NVARCHAR2(100) NOT NULL UNIQUE
);

-- 6. Bảng Sản Phẩm
CREATE TABLE SanPham (
    ma_san_pham VARCHAR2(30) PRIMARY KEY,
    ma_cua_hang NUMBER(10) NOT NULL,
    ma_loai_san_pham NUMBER(5) NOT NULL,
    ten_san_pham NVARCHAR2(255) NOT NULL,
    gia NUMBER(15,3) CHECK (gia > 0),
    so_luong NUMBER(10) CHECK (so_luong >= 0),
    trang_thai_san_pham VARCHAR2(20)
        DEFAULT 'DANG_BAN'
        CHECK (trang_thai_san_pham IN ('DANG_BAN', 'NGUNG_BAN')),
    CONSTRAINT fk_sanpham_cuahang FOREIGN KEY (ma_cua_hang)
        REFERENCES CuaHang(ma_cua_hang),
    CONSTRAINT fk_sanpham_loaisanpham FOREIGN KEY (ma_loai_san_pham)
        REFERENCES LoaiSanPham(ma_loai_san_pham)
);

-- 7. Bảng Đơn Hàng
CREATE TABLE DonHang (
    ma_don_hang VARCHAR2(20) PRIMARY KEY,
    ma_tai_khoan NUMBER(10) NOT NULL,
    ngay_dat DATE DEFAULT SYSDATE,
    trang_thai VARCHAR2(30)
        CHECK (trang_thai IN ('CHO_XAC_NHAN','DA_XAC_NHAN','DANG_GIAO','DA_GIAO','DA_HUY')),
    CONSTRAINT fk_donhang_taikhoan FOREIGN KEY (ma_tai_khoan)
        REFERENCES TaiKhoan(ma_tai_khoan)
);

-- 8. Bảng Chi Tiết Đơn Hàng
CREATE TABLE ChiTietDonHang (
    ma_don_hang VARCHAR2(20),
    ma_san_pham VARCHAR2(30),
    so_luong NUMBER(10) CHECK (so_luong > 0),
    don_gia NUMBER(15,3) CHECK (don_gia >= 0),
    PRIMARY KEY (ma_don_hang, ma_san_pham),
    CONSTRAINT fk_ctdh_donhang FOREIGN KEY (ma_don_hang)
        REFERENCES DonHang(ma_don_hang),
    CONSTRAINT fk_ctdh_sanpham FOREIGN KEY (ma_san_pham)
        REFERENCES SanPham(ma_san_pham)
);

-- 9. Bảng Đơn Vị Vận Chuyển
CREATE TABLE DonViVanChuyen (
    ma_don_vi_van_chuyen VARCHAR2(10) PRIMARY KEY,
    ten_don_vi_van_chuyen NVARCHAR2(100) NOT NULL
);

-- 10. Bảng Người Vận Chuyển
CREATE TABLE NguoiVanChuyen (
    ma_nguoi_van_chuyen NUMBER(10) PRIMARY KEY,
    ma_don_vi_van_chuyen VARCHAR2(10) NOT NULL,
    ho_ten NVARCHAR2(100) NOT NULL,
    sdt CHAR(10) UNIQUE,
    bien_so_xe VARCHAR2(20),
    CONSTRAINT fk_nguoi_vc_donvi FOREIGN KEY (ma_don_vi_van_chuyen)
        REFERENCES DonViVanChuyen(ma_don_vi_van_chuyen)
);

-- 11. Bảng Thông Tin Vận Chuyển
CREATE TABLE ThongTinVanChuyen (
    ma_van_chuyen VARCHAR2(20) PRIMARY KEY,
    ma_don_hang VARCHAR2(20) NOT NULL,
    ma_nguoi_van_chuyen NUMBER(10) NOT NULL,
    dia_chi_giao NVARCHAR2(255) NOT NULL,
    ngay_giao_du_kien DATE,
    trang_thai VARCHAR2(30)
        CHECK (trang_thai IN ('CHO_GIAO','DANG_GIAO','DA_GIAO','HUY')),
    CONSTRAINT fk_ttvanchuyen_donhang FOREIGN KEY (ma_don_hang)
        REFERENCES DonHang(ma_don_hang),
    CONSTRAINT fk_ttvanchuyen_nguoi_vc FOREIGN KEY (ma_nguoi_van_chuyen)
        REFERENCES NguoiVanChuyen(ma_nguoi_van_chuyen)
);

-- 12. Bảng Thông Tin Đánh Giá
CREATE TABLE ThongTinDanhGia (
    ma_san_pham VARCHAR2(30),
    ma_tai_khoan NUMBER(10),
    ma_don_hang VARCHAR2(20),
    noi_dung NVARCHAR2(1000),
    danh_gia NUMBER(1) CHECK (danh_gia BETWEEN 1 AND 5),
    ngay_danh_gia DATE DEFAULT SYSDATE,
    PRIMARY KEY (ma_san_pham, ma_tai_khoan, ma_don_hang),
    CONSTRAINT fk_danhgia_sanpham FOREIGN KEY (ma_san_pham)
        REFERENCES SanPham(ma_san_pham),
    CONSTRAINT fk_danhgia_taikhoan FOREIGN KEY (ma_tai_khoan)
        REFERENCES TaiKhoan(ma_tai_khoan),
    CONSTRAINT fk_danhgia_donhang FOREIGN KEY (ma_don_hang)
        REFERENCES DonHang(ma_don_hang)
);

COMMIT;

desc ThongTinDanhGia;



