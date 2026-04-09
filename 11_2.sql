--tao bang
create table accounts(
    account_id serial primary key ,
    owner_name varchar(100),
    balance numeric(10,2)
);
--insert du lieu
insert into accounts(owner_name, balance)
values ('A',500.00), ('B',300.00);
--1
create or replace procedure chuyen_tien(
    owner_name_1 varchar,
    owner_name_2 varchar,
    amount_bank numeric
)language plpgsql as
$$
    declare
    begin
        if not exists(select 1 from accounts where owner_name=owner_name_1) or not exists(select 1 from accounts where owner_name=owner_name_2) then
            raise exception 'nguoi chuyen hoac nguoi nhan khong ton tai';
        end if;

        if amount_bank>(select accounts.balance from accounts where owner_name=owner_name_1) then
            raise exception 'tai khoan nguoi chuyen khong du tien';
        end if;

        update accounts
        set balance=balance-amount_bank
        where owner_name=owner_name_1;

        update accounts
        set balance=balance+amount_bank
        where owner_name=owner_name_2;

        raise notice 'Giao dich thanh cong';

        exception
        when others then
        raise;
    end;
    $$;

--2
call chuyen_tien('A','C',100.00);