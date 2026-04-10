CREATE DATABASE pg_bank;
-- Bảng tài khoản ngân hàng

CREATE TABLE tai_khoan (

                           id VARCHAR(10) PRIMARY KEY,

                           ten_tai_khoan VARCHAR(100) NOT NULL,

                           so_du DECIMAL(15,2) NOT NULL DEFAULT 0,

                           trang_thai VARCHAR(20) DEFAULT 'ACTIVE',

                           ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

-- Bảng giao dịch

CREATE TABLE giao_dich (

                           id SERIAL PRIMARY KEY,

                           tai_khoan_nguoi_gui VARCHAR(10),

                           tai_khoan_nguoi_nhan VARCHAR(10),

                           so_tien DECIMAL(15,2),

                           loai_giao_dich VARCHAR(50),

                           thoi_gian TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                           trang_thai VARCHAR(20),

                           mo_ta TEXT

);



-- Bảng vé xem phim (cho phần Isolation Levels)

CREATE TABLE ve_phim (

                         id SERIAL PRIMARY KEY,

                         suat_chieu_id VARCHAR(10),

                         ten_phim VARCHAR(100),

                         so_luong_con INT NOT NULL,

                         gia_ve DECIMAL(10,2),

                         ngay_chieu DATE

);

-- Thêm dữ liệu tài khoản

INSERT INTO tai_khoan (id, ten_tai_khoan, so_du, trang_thai) VALUES

                                                                 ('TK001', 'Nguyen Van A', 5000000, 'ACTIVE'),

                                                                 ('TK002', 'Tran Thi B', 3000000, 'ACTIVE'),

                                                                 ('TK003', 'Le Van C', 1000000, 'LOCKED'),

                                                                 ('TK004', 'Pham Thi D', 2000000, 'ACTIVE'),

                                                                 ('TK005', 'Bank Fee Account', 0, 'ACTIVE');



-- Thêm dữ liệu vé phim

INSERT INTO ve_phim (suat_chieu_id, ten_phim, so_luong_con, gia_ve, ngay_chieu) VALUES

                                                                                    ('SC001', 'Avengers: Endgame', 5, 80000, '2024-01-15'),

                                                                                    ('SC002', 'Spider-Man: No Way Home', 3, 75000, '2024-01-16'),

                                                                                    ('SC003', 'The Batman', 1, 85000, '2024-01-17');  -- Chỉ còn 1 vé!

-------------------------------------------------------
--1: TRANSACTION CƠ BẢN - CHUYỂN KHOẢN NGÂN HÀNG
--Bài 1.1: Vấn đề không dùng Transaction
select * from tai_khoan;
-- Code có vấn đề (KHÔNG an toàn):
UPDATE tai_khoan SET so_du = so_du - 1000000 WHERE id = 'TK001';
-- Giả sử dòng này bị lỗi syntax hoặc mất điện
UPDAT tai_khoan SET so_du = so_du + 1000000 WHERE id = 'TK002';  -- Lỗi cố ý
--Bài 1.2: Giải pháp với Transaction
create or replace procedure chuyen_khoan(
    id_in_1 varchar,
    id_in_2 varchar,
    amount_in numeric
)language plpgsql as
$$
    declare

    begin
        if (select so_du from tai_khoan where id=id_in_1)<amount_in then
            raise exception 'Tai khoan cua nguoi gui id % khong du!',id_in_1;
        end if;

        update tai_khoan
        set so_du=so_du-amount_in
        where id=id_in_1;

        update tai_khoan
        set so_du=so_du+amount_in
        where id=id_in_2;

        raise notice 'Chuyen khoan thanh cong!';
    end;
    $$;
--goi procedure
select * from tai_khoan;
call chuyen_khoan('TK001','TK002',1000000);
select * from tai_khoan;
----------------------------
--PHẦN 2: STORED PROCEDURE VỚI TRANSACTION
--Bài 2.1: Tạo Procedure chuyển khoản hoàn chỉnh
create or replace procedure chuyen_khoan_an_toan(
    p_tk_nguoi_gui varchar(10),
    p_tk_nguoi_nhan varchar(10),
    p_so_tien decimal
)language plpgsql as
$$
    declare
        v_id_nguoi_gui varchar;
        v_so_du_nguoi_gui decimal(15,2);
        v_trang_thai_nguoi_gui varchar;
    begin
        select id,so_du,trang_thai into v_id_nguoi_gui,v_so_du_nguoi_gui,v_trang_thai_nguoi_gui
        from tai_khoan
        where id=p_tk_nguoi_gui;
        --Exception:
        --1: sai id
        if v_id_nguoi_gui isnull or not exists(select id from tai_khoan where id=p_tk_nguoi_nhan) then
            raise exception 'Tai khoan nguoi gui hoac nguoi nhan khong hop le, vui long thu lai';
        --2: chua active
        elseif v_trang_thai_nguoi_gui!='ACTIVE' or (select trang_thai from tai_khoan where id=p_tk_nguoi_nhan)!='ACTIVE' then
            raise exception 'Tai khoan nguoi gui hoac nguoi nhan chua duoc kich hoat, vui long thu lai';
        --3: khong du so du
        elseif v_so_du_nguoi_gui<p_so_tien then
            raise exception E'Tai khoan nguoi gui khong du tien!\nSo du con lai: %',v_so_du_nguoi_gui;
        end if;

        --ghi log giao dich
        insert into giao_dich(tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich,trang_thai)
        values (p_tk_nguoi_gui,p_tk_nguoi_nhan,p_so_tien,'CHUYEN TIEN','COMPLETE');
        --tru tien nguoi gui
        update tai_khoan
        set so_du=so_du-p_so_tien
        where id=v_id_nguoi_gui;
        --cong tien nguoi nhan
        update tai_khoan
        set so_du=so_du+p_so_tien
        where tai_khoan.id=p_tk_nguoi_nhan;
        --commit
        raise notice E'Chuyen tien thanh cong!\nVui long kiem tra lai tai khoan';
    end;
    $$;
--Bài 2.2: Test các trường hợp thực tế
-- TH1: Chuyển thành công
call chuyen_khoan_an_toan('TK001', 'TK002', 500000);
select * from tai_khoan order by id;
select * from giao_dich order by thoi_gian desc ;
-- TH2: Số dư không đủ
call chuyen_khoan_an_toan('TK001', 'TK002', 10000000);
-- TH3: Tài khoản bị khóa
call chuyen_khoan_an_toan('TK003', 'TK001', 100000);
-- TH4: Tài khoản không tồn tại
call chuyen_khoan_an_toan('TK999', 'TK001', 100000);
-----------------------------------------
--PHẦN 3: ISOLATION LEVELS - BÀI TOÁN BÁN VÉ & CẠNH TRANH DỮ LIỆU
--Bài 3.1: Mô phỏng "Race Condition" trong bán vé --> Bị dirty read
--Bài 3.2: Giải quyết với Isolation Level phù hợp
set transaction isolation level repeatable read ;
begin ;
select ve_phim.so_luong_con from ve_phim where suat_chieu_id='SC003';

UPDATE ve_phim SET so_luong_con = so_luong_con - 1
WHERE suat_chieu_id = 'SC003' AND so_luong_con > 0;
commit;
-------------------------------------------
--PHẦN 4: XỬ LÝ LỖI PHỨC TẠP VỚI SAVEPOINT
--Bài 4.1: Nghiệp vụ "CHUYỂN TIỀN VÀ MUA VÉ"
create or replace procedure chuyen_tien_va_mue_ve()
language plpgsql as
$$
    declare
        v_so_luong_con int;
        v_gia_ve decimal;
    begin
        --chuyen tien
        call chuyen_khoan_an_toan('TK004','TK001',1000000);
        --chuyen phi vao tk ngan hang
        call chuyen_khoan_an_toan('TK004','TK005',5000);
        --mua 2 ve: tao transaction
        --khong du 2 ve-> bao loi
    begin
        select so_luong_con,gia_ve into v_so_luong_con,v_gia_ve
        from ve_phim
        where suat_chieu_id='SC001';
        if v_so_luong_con <2 then
            raise exception 'Khong du so luong ve con lai';
        end if;
        update ve_phim
        set so_luong_con=so_luong_con-2
        where suat_chieu_id='SC001';
        --tru tien tk TK004
        update tai_khoan
        set so_du=so_du-v_gia_ve*2
        where id='TK004';

        raise notice 'Thuc hien chuyen tien va mua ve thanh cong!';

    exception when others then
        raise notice 'Loi mua ve: %. Giao dich chuyen tien van duoc giu lai.', SQLERRM;
    end;
end;
$$;
--Bài 4.2: Test nghiệp vụ phức tạp
select * from tai_khoan;
select * from ve_phim order by id;
--Th1: con 5 ve mua oke
CALL chuyen_tien_va_mue_ve();
--th2: con 0 ve--> mua-->bao loi
update ve_phim
set so_luong_con=0
where suat_chieu_id='SC001';

call chuyen_tien_va_mue_ve();




