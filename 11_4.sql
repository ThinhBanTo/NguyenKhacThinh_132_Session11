--tao bang
create table accounts(
    account_id serial primary key ,
    owner_name varchar(100),
    balance numeric(10,2)
);

create table transactions(
    trans_id serial primary key ,
    account_id int references accounts(account_id),
    amount numeric(12,2),
    trans_type varchar(20) check (trans_type in ('WITHDRAW','DEPOSIT')),
    created_at timestamp default now()
);

--1
create or replace procedure withdraw(
    account_id_in int,
    amount_in numeric(12,2)
)language plpgsql as
$$
    declare
        exist_id int;
        max_amount numeric(12,2);
    begin
        select account_id,balance into exist_id,max_amount
        from accounts
        where account_id=account_id_in;

        if not found then
            raise exception 'Tai khoan id % nay khong ton tai, vui long thu lai',account_id_in;
        end if;

        if amount_in>max_amount then
            raise exception E'Tai khoan khong du tien de rut!\nSo tien con lai la: %',max_amount;
        end if;

        insert into transactions(account_id, amount, trans_type)
        values (account_id_in,amount_in,'WITHDRAW');

        update accounts
        set balance=balance-amount_in
        where account_id=account_id_in;

        raise notice 'Rut tien thanh cong';

        exception
        when others then
        raise;
    end;
    $$;

--2
select * from accounts;
select * from transactions;

--rut dung:
call withdraw(1,50.00);
--rut fail:
call withdraw(3,150.00);
call withdraw(1,550.00);
